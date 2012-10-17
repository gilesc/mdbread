from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import commands

def pkgconfig(*packages, **kw):
    flag_map = {'-I': 'include_dirs', 
                '-L': 'library_dirs', 
                '-l': 'libraries'}
    for token in commands.getoutput("pkg-config --libs --cflags %s" % ' '.join(packages)).split():
        kw.setdefault(flag_map.get(token[:2]), []).append(token[2:])
    return kw

setup(
    name='mdbread',
    version='0.1',
    description='Reader for MS Access MDB files.',
    author='Cory Giles',
    author_email='cory.b.giles@gmail.com',
    url='http://corygil.es/',
    cmdclass={'build_ext': build_ext},
    ext_modules = [Extension("mdbread", ["mdbread.pyx"], 
                             **pkgconfig("libmdb"))],
    classifiers=[
        "Development Status :: 2 - Pre-Alpha",
        "Intended Audience :: Developers",
        "Natural Language :: English",
        "Operating System :: POSIX",
        "Operating System :: MacOS X",
        "License :: OSI Approved :: MIT License",
        "Topic :: Database"]
)
