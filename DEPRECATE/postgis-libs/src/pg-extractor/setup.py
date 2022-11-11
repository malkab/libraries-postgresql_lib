from setuptools import setup

setup(name='mlk-pg-extractor',
      version='0.1',
      description='Extract PostGIS table schema and create copy scripts',
      author='Juan Pedro Perez Alcantara',
      author_email='jp.perez.alcantara@gmail.com',
      license='MIT',
      zip_safe=False,
      packages=["pg_extractor"],
      scripts=["mlk-pg-extractor", "mlk-pg-extractor-batch"])
