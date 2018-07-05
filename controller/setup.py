from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import numpy

ext = Extension("cyueye", sources = ["cyueye.pyx"], libraries=["ueye_api"])

setup(
    name="cyueye", ext_modules = cythonize([ext]), include_dirs=[numpy.get_include()]
)
