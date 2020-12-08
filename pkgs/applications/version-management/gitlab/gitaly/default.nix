{ stdenv, fetchFromGitLab, fetchFromGitHub, buildGoModule, ruby
, bundlerEnv, pkgconfig
# libgit2 + dependencies
, libgit2, openssl, zlib, pcre, http-parser }:

let
  rubyEnv = bundlerEnv rec {
    name = "gitaly-env";
    inherit ruby;
    copyGemFiles = true;
    gemdir = ./.;
    gemset =
      let x = import (gemdir + "/gemset.nix");
      in x // {
        # grpc expects the AR environment variable to contain `ar rpc`. See the
        # discussion in nixpkgs #63056.
        grpc = x.grpc // {
          patches = [ ../fix-grpc-ar.patch ];
          dontBuild = false;
        };
      };
  };
in buildGoModule rec {
  version = "13.6.1";
  pname = "gitaly";

  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitaly";
    rev = "v${version}";
    sha256 = "02w7pf7l9sr2nk8ky9b0d5b4syx3d9my65h2kzvh2afk7kv35h5y";
  };

  patches = [
    # https://gitlab.com/gitlab-org/gitaly/-/issues/3330
    # remove when upstream has enabled libgit2 1.1.0 support
    ./0001-use-git2go-v31.patch
  ];

  vendorSha256 = "182s4m6z8dgfnpwir8njjb2s8fnxw4yivim2b252nvl34hsa7550";

  passthru = {
    inherit rubyEnv;
  };

  buildFlags = [ "-tags=static,system_libgit2" ];
  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ rubyEnv.wrappedRuby libgit2 openssl zlib pcre http-parser ];
  doCheck = false;

  postInstall = ''
    mkdir -p $ruby
    cp -rv $src/ruby/{bin,lib,proto,git-hooks} $ruby
  '';

  outputs = [ "out" "ruby" ];

  meta = with stdenv.lib; {
    homepage = "https://gitlab.com/gitlab-org/gitaly";
    description = "A Git RPC service for handling all the git calls made by GitLab";
    platforms = platforms.linux;
    maintainers = with maintainers; [ roblabla globin fpletz talyz ];
    license = licenses.mit;
  };
}
