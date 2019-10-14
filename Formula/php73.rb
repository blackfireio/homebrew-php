require File.expand_path("../../Abstract/abstract-php", __FILE__)

class Php73 < AbstractPhp
  init
  desc "PHP Version 7.3"
  revision 13

  include AbstractPhpVersion::Php72Defs

  url PHP_SRC_TARBALL
  sha256 PHP_CHECKSUM[:sha256]

  head PHP_GITHUB_URL, :branch => PHP_BRANCH

  def php_version
    "7.3"
  end

  def php_version_path
    "73"
  end
end
