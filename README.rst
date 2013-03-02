=======
mdbread
=======

A simple Cython-based wrapper for the excellent MDBTools package to read data from MS Access MDB files. Currently, it supports a few basic operations like listing tables and table columns, iterating through rows, or exporting a table to a pandas DataFrame. It does not support SQL or inserts.

Installation
============

The prerequisites are:

- pkg-config
- glib-2.0
- mdbtools

On Ubuntu this can be satisfied by:

.. code-block:: bash

    sudo apt-get install -y mdbtools-dev

On ArchLinux:

.. code-block:: bash

    yaourt -S mdbtools

On OSX:

.. code-block:: bash

    brew install mdbtools

mdbtools is also available under Cygwin. However, I haven't tested this package on Windows and there are much easier ways to use Access files under Windows, such as ODBC or the Python Windows API.

To complete the installation, run the following command from this directory:

.. code-block:: bash

    (sudo) python setup.py install

Usage
=====

.. code-block:: python

    >>> import mdbread
    >>> db = mdbread.MDB("MyDB.mdb")
    >>> print db.tables
    ["tbl1", "tbl2", "tbl3"]

    >>> tbl = db["tbl1"]
    >>> print tbl.columns
    ["foo","bar","baz"]


To get the data in a table, you have three options:

- **mdbread.Table.records()** returns a generator of dictionaries, where the keys are column names and the values are the data.
- **iter(mdbread.Table)** will return a namedtuple for each row. You can also use this form with **for row in tbl:**
- **mdbread.Table.to_data_frame()** will return a pandas DataFrame containing all the data for the entire table (possibly requiring lots of memory) .

Limitations
===========

The biggest current limitation is that not all MS Access datatypes are coerced to Python objects. So, if you are iterating through rows in an MDB and the column has an unusual type, the program may fail with a KeyError. You can file an issue or e-mail me and I can add your favorite datatype. Or, you can simply add your own coercion to the "transformers" dictionary within mdbread.pyx. I hope to find time to fix this soon.

Contributions & License
=======================

Pull requests and issues are welcomed.

MIT License.
