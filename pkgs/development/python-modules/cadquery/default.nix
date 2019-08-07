{ lib
, buildPythonPackage
, fetchFromGitHub
, pyparsing
, opencascade
, stdenv
, python
, cmake
, swig
, ninja
, smesh
, freetype
, libGL
, libGLU
, libX11
, six
}:

let 
  pythonocc-core-cadquery = stdenv.mkDerivation rec {
    pname = "pythonocc-core-cadquery";
    version = "0.18.2";

    src = fetchFromGitHub {
      owner = "CadQuery";
      repo = "pythonocc-core";
      # no proper release to to use, this commit copied from the Anaconda receipe
      rev = "701e924ae40701cbe6f9992bcbdc2ef22aa9b5ab";
      sha256 = "07zmiiw74dyj4v0ar5vqkvk30wzcpjjzbi04nsdk5mnlzslmyi6c";
    };

    nativeBuildInputs = [ 
      cmake
      swig
      ninja
    ];

    buildInputs = [
      python
      opencascade
      smesh
      freetype
      libGL
      libGLU
      libX11
    ];

    propagatedBuildInputs = [
      six
    ];

    cmakeFlags = [
      "-Wno-dev"
      "-DPYTHONOCC_INSTALL_DIRECTORY=${placeholder "out"}/${python.sitePackages}/OCC"
      "-DSMESH_INCLUDE_PATH=${smesh}/include/smesh"
      "-DSMESH_LIB_PATH=${smesh}/lib"
      "-DPYTHONOCC_WRAP_SMESH=TRUE"
    ];
  };

in
  buildPythonPackage rec {
    pname = "cadquery";
    version = "2.0RC0";
  
    src = fetchFromGitHub {
      owner = "CadQuery";
      repo = pname;
      rev = version;
      sha256 = "1xgd00rih0gjcnlrf9s6r5a7ypjkzgf2xij2b6436i76h89wmir3";
    };
  
    buildInputs = [
      opencascade
    ];
  
    propagatedBuildInputs = [
      pyparsing
      pythonocc-core-cadquery
    ];
  
    meta = with lib; {
      description = "Parametric scripting language for creating and traversing CAD models";
      homepage = https://github.com/CadQuery/cadquery;
      license = licenses.asl20;
      maintainers = [ maintainers.costrouc maintainers.marcus7070 ];
    };
  }
