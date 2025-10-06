class Nwchem < Formula
  desc "High-performance computational chemistry tools"
  homepage "https://nwchemgit.github.io"
  url "https://github.com/edoapra/nwchem/releases/download/vnightly-release/nwchem-nightly-release.revision-39ce3184-src.2025-10-06.tar.xz"
  version "7.3.0"
  sha256 "b50e65b3c42a2cd8e9dc5793ec6fe7c86505758f780de67869a2a687c2aed887"
  license "ECL-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)-release$/i)
    strategy :github_latest
  end

  no_autobump! because: :requires_manual_review

  bottle do
    sha256                               arm64_tahoe:   "dc8414de3195b270a0682dff08d17d0f0a69385cca360825ea73f18f7447e5f7"
    sha256                               arm64_sequoia: "9e7d38520a012a3b258b13b79d2e21fa1f65c69d6a80e442db8543c301ebf8c4"
    sha256                               arm64_sonoma:  "cbd863d1ffb5625c8551e5bccae2ac62d2d09af075e9e10956033d4e3ddaa2b9"
    sha256                               arm64_ventura: "7fce8b94f1233bcf022bfaa7456abf9587baeb3319ffc47b725dd83eb1d83b6c"
    sha256 cellar: :any,                 sonoma:        "2e2473703a5f2d268135f72189557e4c150059774540e9c89c74b66774a6931f"
    sha256 cellar: :any,                 ventura:       "dd0b5829832ca473260b2da63478f93cee2e4bdf388898f0fc546e1f2e2a52f9"
    sha256                               arm64_linux:   "9f72b9c318ebea8a8f992aa16617e1c928d9402a487a5baf48887c6d65c68251"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f0aa305807bdecc60ae25c0b3798ea4cc9fa9251be63dda2e7c460351106b393"
  end

  depends_on "gcc" # for gfortran
  depends_on "hwloc"
  depends_on "libxc"
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "pkgconf"
  depends_on "python@3.13"
  depends_on "scalapack"

  uses_from_macos "libxcrypt"

  def install
    pkgshare.install "QA"

    cd "src" do
      (prefix/"etc").mkdir
      (prefix/"etc/nwchemrc").write <<~EOS
        nwchem_basis_library #{pkgshare}/libraries/
        nwchem_nwpw_library #{pkgshare}/libraryps/
        ffield amber
        amber_1 #{pkgshare}/amber_s/
        amber_2 #{pkgshare}/amber_q/
        amber_3 #{pkgshare}/amber_x/
        amber_4 #{pkgshare}/amber_u/
        spce    #{pkgshare}/solvents/spce.rst
        charmm_s #{pkgshare}/charmm_s/
        charmm_x #{pkgshare}/charmm_x/
      EOS

      inreplace "util/util_nwchemrc.F", "/etc/nwchemrc", etc/"nwchemrc"

      # needed to use python 3.X to skip using default python2
      ENV["PYTHONVERSION"] = Language::Python.major_minor_version "python3.13"
      ENV["BLASOPT"] = "-L#{Formula["openblas"].opt_lib} -lopenblas"
      ENV["LAPACK_LIB"] = "-L#{Formula["openblas"].opt_lib} -lopenblas"
      ENV["BLAS_SIZE"] = "4"
      ENV["SCALAPACK"] = "-L#{Formula["scalapack"].opt_prefix}/lib -lscalapack"
      ENV["SCALAPACK_SIZE"] = "4"
      ENV["USE_64TO32"] = "y"
      ENV["USE_HWOPT"] = "n"
      ENV["OPENBLAS_USES_OPENMP"] = "y"
      ENV["LIBXC_LIB"] = Formula["libxc"].opt_lib.to_s
      ENV["LIBXC_INCLUDE"] = Formula["libxc"].opt_include.to_s
      os = OS.mac? ? "MACX64" : "LINUX64"
      system "make", "nwchem_config", "NWCHEM_MODULES=all python gwmol", "USE_MPI=Y"
      system "make", "NWCHEM_TARGET=#{os}", "USE_MPI=Y"
      bin.install "../bin/#{os}/nwchem"
      pkgshare.install "basis/libraries"
      pkgshare.install "basis/libraries.bse"
      pkgshare.install "nwpw/libraryps"
      pkgshare.install Dir["data/*"]
    end
  end

  test do
    cp_r pkgshare/"QA", testpath
    cd "QA" do
      ENV["OMP_NUM_THREADS"] = "1"
      ENV["NWCHEM_TOP"] = testpath
      ENV["NWCHEM_TARGET"] = OS.mac? ? "MACX64" : "LINUX64"
      ENV["NWCHEM_EXECUTABLE"] = bin/"nwchem"
      system "./runtests.mpi.unix", "procs", "0", "dft_he2+", "pyqa3", "prop_mep_gcube", "pspw", "tddft_h2o", "tce_n2"
    end
  end
end
