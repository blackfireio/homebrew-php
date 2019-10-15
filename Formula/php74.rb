require File.expand_path("../../Abstract/abstract-php74", __FILE__)

class Php74 < AbstractPhp74
  init
  desc "PHP Version 7.4"
  revision 20

  include AbstractPhpVersion::Php74Defs

  url PHP_SRC_TARBALL
  sha256 PHP_CHECKSUM[:sha256]

  head PHP_GITHUB_URL, :branch => PHP_BRANCH

  def php_version
    "7.4"
  end

  def php_version_path
    "74"
  end
end
