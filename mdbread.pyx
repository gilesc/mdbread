import pandas
import time
from collections import namedtuple

cdef extern from "glib.h":
    void* g_malloc(int)
    void* g_malloc0(int)
    void g_free(void*)
    void* g_ptr_array_index(GPtrArray*, int)
    ctypedef struct GPtrArray:
        pass

cdef extern from "mdbsql.h":
    # void mdb_init()
    ctypedef struct MdbHandle:
        int num_catalog
        GPtrArray* catalog

    MdbHandle* mdb_open(char*,int)
    enum MdbFileFlags:
        MDB_NOFLAGS
    int MDB_TABLE
    int MDB_BIND_SIZE
    int MDB_ANY

    int mdb_read_catalog(MdbHandle*, int) 
    ctypedef struct MdbCatalogEntry:
        char* object_name
        int object_type

    ctypedef struct MdbTableDef:
        GPtrArray* columns
        int num_cols

    ctypedef struct MdbColumn:
        int col_type
        char* name

    MdbTableDef* mdb_read_table_by_name(MdbHandle*,char*,int)
    void mdb_read_columns(MdbTableDef*)
    void mdb_rewind_table(MdbTableDef*)
    
    char* mdb_get_colbacktype_string(MdbColumn*)

    void mdb_bind_column(MdbTableDef*,int,char*,int*)
    int mdb_fetch_row(MdbTableDef*)
    void mdb_close(MdbHandle*)
    void mdb_exit()

transformers = {
    "Long Integer": lambda x: int(x) if x != "" else "",
    "Single": float,
    "Boolean": lambda x: bool(int(x)),
    "Text": str,
    "DateTime": lambda dt: time.strptime(dt, "%m/%d/%y %H:%M:%S"),
    "Memo/Hyperlink": str
}

cdef class MDB(object):
    cdef MdbHandle* _handle

    def __init__(self, path):
        # mdb_init()
        self._handle = mdb_open(path, MDB_NOFLAGS)
        if not mdb_read_catalog(self._handle, MDB_ANY):
            raise Exception("File is not a valid Access database!")

    @property
    def tables(self):
        cdef MdbCatalogEntry* entry

        tables = []
        for i in xrange(self._handle.num_catalog):
            entry = <MdbCatalogEntry*> \
                    g_ptr_array_index(self._handle.catalog, i)
            name = entry.object_name
            if entry.object_type == MDB_TABLE:
                if not "MSys" in name:
                    tables.append(name)
        return tables

    def __iter__(self):
        for tbl in self.tables:
            yield Table(self, tbl)

    def __getitem__(self, key):
        return Table(self, key)

    def __del__(self):
        mdb_close(self._handle)
        mdb_exit()

cdef class Table(object):
    cdef MdbTableDef* tbl
    cdef int ncol
    cdef char* name
    cdef char** bound_values
    cdef int* bound_lens

    def __init__(self, MDB mdb, bytes name):
        self.name = name
        self.tbl = mdb_read_table_by_name(mdb._handle,
                                          self.name,MDB_TABLE)
        self.ncol = self.tbl.num_cols
        self.bound_values = \
            <char**> g_malloc(<int>(self.ncol * sizeof(char*)))
        self.bound_lens = \
            <int*> g_malloc(<int> (self.ncol * sizeof(int)))

        for j in xrange(self.ncol):
            self.bound_values[j] = <char*> g_malloc0(MDB_BIND_SIZE)

        mdb_read_columns(self.tbl)

    def _column_names(self):
        names = []
        cdef MdbColumn* col
        for j in xrange(self.ncol):
            col = <MdbColumn*> g_ptr_array_index(self.tbl.columns, j)
            names.append(str(col.name))
        return names

    @property
    def columns(self):
        return self._column_names()

    def records(self):
        Row = namedtuple("Row",self.columns)
        for row in self:
            yield Row(*row)

    def __iter__(self):
        mdb_rewind_table(self.tbl)

        cdef unsigned int j
        cdef MdbColumn* col
        cdef char* col_type
        col_types = []

        for j in xrange(self.ncol):
            col = <MdbColumn*> g_ptr_array_index(self.tbl.columns, j)
            col_type = mdb_get_colbacktype_string(col)
            col_types.append(col_type)

            mdb_bind_column(self.tbl,j+1,
                            self.bound_values[j],
                            &self.bound_lens[j])

        _transformers = [transformers[t] for t in col_types]
        while mdb_fetch_row(self.tbl):
            row = [_transformers[j](self.bound_values[j]) 
                   for j in xrange(self.ncol)]
            yield row

    def __del__(self):
        for i in xrange(self.ncol):
            g_free(self.bound_values[i])

        g_free(self.bound_values)
        g_free(self.bound_lens)
 
    def to_data_frame(self):
        rows = []
        for row in self:
            rows.append(row)
        names = self._column_names()
        return pandas.DataFrame(rows, columns=names)

