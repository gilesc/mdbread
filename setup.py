from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

import subprocess as sp
import sys

def pkgconfig(*packages, **kw):
    flag_map = {'-I': 'include_dirs', 
                '-L': 'library_dirs', 
                '-l': 'libraries'}
    cmd = ["pkg-config", "--libs", "--cflags"]
    cmd.extend(packages)
    try:
        out = sp.check_output(cmd, universal_newlines=True)
    except:
        raise SystemExit("libmdb (or pkg-config) is not installed! Aborting...")
    kw = {}
    for token in out.split():
        kw.setdefault(flag_map.get(token[:2]), []).append(token[2:])
    return kw

setup(
    name='mdbread',
    version='0.1.1',
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
