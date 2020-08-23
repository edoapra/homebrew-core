class Acme < Formula
  desc "Crossassembler for multiple environments"
  homepage "https://sourceforge.net/projects/acme-crossass/"
  url "https://svn.code.sf.net/p/acme-crossass/code-0/trunk", revision: "266"
  version "0.97"
  license "GPL-2.0-or-later"

  bottle do
    cellar :any_skip_relocation
    sha256 "54080f9a08a3f958c5a024fd536c2308c392521a4a4092afb115f368b3256fd2" => :catalina
    sha256 "53ddd3c05dea30a12436e997a68ab50670bd9dbe771e3c3a6d7216c0240c6e07" => :mojave
    sha256 "8ed3df0ed73b3f995ca33b357c00f54b03f16ec2effd61eca985b04a82eb40b6" => :high_sierra
  end

  def install
    system "make", "-C", "src", "install", "BINDIR=#{bin}"
    doc.install Dir["docs/*"]
  end

  test do
    path = testpath/"a.asm"
    path.write <<~EOS
      !to "a.out", cbm
      * = $c000
      jmp $fce2
    EOS

    system bin/"acme", path
    code = File.open(testpath/"a.out", "rb") { |f| f.read.unpack("C*") }
    assert_equal [0x00, 0xc0, 0x4c, 0xe2, 0xfc], code
  end
end
