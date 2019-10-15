# encoding: utf-8

require "formula"
require File.join(File.dirname(__FILE__), "abstract-php-version")

class AbstractPhp74 < Formula
  def self.init
    homepage "https://php.net"

    # So PHP extensions don't report missing symbols
    skip_clean "bin", "sbin"

    head do
      depends_on "autoconf" => :build
      depends_on "re2c" => :build
      depends_on "flex" => :build
      depends_on "bison@3.4" => :build
      depends_on "pkg-config" => :build
    end

    # obtain list of php formulas
    php_formulas = Formula.names.grep(Regexp.new('^php\d\d$')).sort

    # remove our self from the list
    php_formulas.delete(name.split("::")[2].downcase)

    # conflict with out php versions
    php_formulas.each do |php_formula_name|
      conflicts_with php_formula_name, :because => "different php versions install the same binaries."
    end

    depends_on "curl"
    depends_on "gettext"
    depends_on "gmp" => :optional
    depends_on "icu4c"
    depends_on "imap-uw" if build.include?("with-imap")
    depends_on "libxml2"
    depends_on "readline"
    depends_on "oniguruma" if name.split("::")[2].downcase.start_with?("php74")
    depends_on "openssl"
  end

  # Fixes the pear .lock permissions issue that keeps it from operating correctly.
  # Thanks mistym & #machomebrew
  skip_clean "lib/php/.lock"

  def config_path
    etc+"php"+php_version
  end

  def home_path
    File.expand_path("~")
  end

  def php_version
    raise "Unspecified php version"
  end

  def php_version_path
    raise "Unspecified php version path"
  end

  def install
    # Ensure this php has a version specified
    php_version
    php_version_path

    # Not removing all pear.conf and .pearrc files from PHP path results in
    # the PHP configure not properly setting the pear binary to be installed
    config_pear = "#{config_path}/pear.conf"
    user_pear = "#{home_path}/pear.conf"
    config_pearrc = "#{config_path}/.pearrc"
    user_pearrc = "#{home_path}/.pearrc"
    if File.exist?(config_pear) || File.exist?(user_pear) || File.exist?(config_pearrc) || File.exist?(user_pearrc)
      opoo "Backing up all known pear.conf and .pearrc files"
      opoo <<-INFO
If you have a pre-existing pear install outside
         of homebrew-php, or you are using a non-standard
         pear.conf location, installation may fail.
INFO
      mv(config_pear, "#{config_pear}-backup") if File.exist? config_pear
      mv(user_pear, "#{user_pear}-backup") if File.exist? user_pear
      mv(config_pearrc, "#{config_pearrc}-backup") if File.exist? config_pearrc
      mv(user_pearrc, "#{user_pearrc}-backup") if File.exist? user_pearrc
    end

    begin
      _install
      rm_f("#{config_pear}-backup") if File.exist? "#{config_pear}-backup"
      rm_f("#{user_pear}-backup") if File.exist? "#{user_pear}-backup"
      rm_f("#{config_pearrc}-backup") if File.exist? "#{config_pearrc}-backup"
      rm_f("#{user_pearrc}-backup") if File.exist? "#{user_pearrc}-backup"
    rescue StandardError
      mv("#{config_pear}-backup", config_pear) if File.exist? "#{config_pear}-backup"
      mv("#{user_pear}-backup", user_pear) if File.exist? "#{user_pear}-backup"
      mv("#{config_pearrc}-backup", config_pearrc) if File.exist? "#{config_pearrc}-backup"
      mv("#{user_pearrc}-backup", user_pearrc) if File.exist? "#{user_pearrc}-backup"
      raise
    end
  end

  def apache_apxs
    if build.with?("httpd")
      ["sbin", "bin"].each do |dir|
        if File.exist?(location = "#{HOMEBREW_PREFIX}/#{dir}/apxs")
          return location
        end
      end
    else
      "/usr/sbin/apxs"
    end
  end

  def default_config
    "./php.ini-development"
  end

  def skip_pear_config_set?
    build.without? "pear"
  end

  def patches
    # Bug in PHP 5.x causes build to fail on OSX 10.5 Leopard due to
    # outdated system libraries being first on library search path:
    # https://bugs.php.net/bug.php?id=44294
    "https://gist.github.com/ablyler/6579338/raw/5713096862e271ca78e733b95e0235d80fed671a/Makefile.global.diff" if MacOS.version == :leopard
  end

  def install_args
    # Prevent PHP from harcoding sed shim path
    ENV["lt_cv_path_SED"] = "sed"
    ENV["PKG_CONFIG_PATH"] = "#{Formula["libxml2"].opt_prefix}/lib/pkgconfig:#{ENV["PKG_CONFIG_PATH"]}"

    # Ensure system dylibs can be found by linker on Sierra
    ENV["SDKROOT"] = MacOS.sdk_path if MacOS.version == :sierra

    args = [
      "--prefix=#{prefix}",
      "--localstatedir=#{var}",
      "--sysconfdir=#{config_path}",
      "--with-config-file-path=#{config_path}",
      "--with-config-file-scan-dir=#{config_path}/conf.d",
      "--mandir=#{man}",
      "--enable-mbstring",
      "--enable-pcntl",
      "--enable-mysqlnd",
      "--enable-opcache",
      "--with-curl",
      "--with-mbstring",
      "--with-openssl",
      "--with-readline",
      "--with-recode",
      "--with-zlib",
      "--with-pgsql",
      "--with-pear",
    ]

    args << "--with-mysql-sock=/tmp/mysql.sock"
    args << "--with-mysqli=mysqlnd"
    args << "--with-pdo-mysql=mysqlnd"

    args << "--with-openssl-dir=" + Formula["openssl"].opt_prefix.to_s

    # args << "LIBXML_CFLAGS=-I#{Formula["libxml2"].opt_prefix}/include/libxml2"
    # args << "LIBXML_LIBS=-L#{Formula["libxml2"].opt_prefix}/lib"

    # args << "KERBEROS_CFLAGS=-I#{Formula["krb5"].opt_prefix}/include"
    # args << "KERBEROS_LIBS=-L#{Formula["krb5"].opt_prefix}/lib"

    # args << "OPENSSL_CFLAGS=-I#{Formula["openssl"].opt_prefix}/include"
    # args << "OPENSSL_LIBS=-L#{Formula["openssl"].opt_prefix}/lib"

    # args << "SQLITE_CFLAGS=-I#{Formula["sqlite"].opt_prefix}/include"
    # args << "SQLITE_LIBS=-L#{Formula["sqlite"].opt_prefix}/lib"

    # args << "ZLIB_CFLAGS=-I#{Formula["zlib"].opt_prefix}/include"
    # args << "ZLIB_LIBS=-L#{Formula["zlib"].opt_prefix}/lib"

    # args << "CURL_CFLAGS=-I#{Formula["curl"].opt_prefix}/include"
    # args << "CURL_LIBS=-L#{Formula["curl"].opt_prefix}/lib"

    # args << "ONIG_CFLAGS=-I#{Formula["oniguruma"].opt_prefix}/include"
    # args << "ONIG_LIBS=-L#{Formula["oniguruma"].opt_prefix}/lib"

    # args << "XSL_CFLAGS=-I#{Formula["libxslt"].opt_prefix}/include"
    # args << "XSL_LIBS=-L#{Formula["libxslt"].opt_prefix}/lib"

    # args << "LIBZIP_CFLAGS=-I#{Formula["libzip"].opt_prefix}/include"
    # args << "LIBZIP_LIBS=-L#{Formula["libzip"].opt_prefix}/lib"

    if build.without? "pear"
      args << "--without-pear"
    end

    if build.with? "postgresql"
      if Formula["postgresql"].opt_prefix.directory?
      else
        args << "--with-pgsql=#{`pg_config --includedir`}"
        args << "--with-pdo-pgsql=#{`which pg_config`}"
      end
    end

    unless php_version.start_with?("5.3")
      # dtrace is not compatible with phpdbg: https://github.com/krakjoe/phpdbg/issues/38
      if build.without? "phpdbg"
        args << "--enable-dtrace"
        args << "--disable-phpdbg"
      else
        args << "--enable-phpdbg"

        if build.with? "debug"
          args << "--enable-phpdbg-debug"
        end
      end

      args << "--enable-zend-signals"
    end

    if build.with? "webp"
      args << "--with-webp-dir=#{Formula['webp'].opt_prefix}"
    end

    if build.with? "libvpx"
      args << "--with-vpx-dir=#{Formula['libvpx'].opt_prefix}"
    end

    if build.with? "thread-safety"
      args << "--enable-maintainer-zts"
    end

    args << "--with-sodium"

    args
  end

  def _install
    system "./buildconf", "--force" if build.head?
    system "./configure", *install_args

    inreplace "Makefile" do |s|
      s.change_make_var! "EXTRA_LIBS", "\\1 -lstdc++"
    end

    system "make"
    ENV.deparallelize # parallel install fails on some systems
    system "make install"

    # Prefer relative symlink instead of absolute for relocatable bottles
    ln_s "phar.phar", bin+"phar", :force => true if File.exist? bin+"phar.phar"

    # Install new php.ini unless one exists
    config_path.install default_config => "php.ini" unless File.exist? config_path+"php.ini"

    chmod_R 0775, lib+"php"

    system bin+"pear", "config-set", "php_ini", config_path+"php.ini", "system" unless skip_pear_config_set?
  end

  def caveats
    s = []

    s << <<~EOS
      The php.ini file can be found in:
          #{config_path}/php.ini
    EOS

    if build.with? "pear"
      s << <<~EOS
        ✩✩✩✩ PEAR ✩✩✩✩

        If PEAR complains about permissions, 'fix' the default PEAR permissions and config:

            chmod -R ug+w #{lib}/php
            pear config-set php_ini #{etc}/php/#{php_version}/php.ini system
      EOS
    end

    s << <<~EOS
      ✩✩✩✩ Extensions ✩✩✩✩

      If you are having issues with custom extension compiling, ensure that you are using the brew version, by placing #{HOMEBREW_PREFIX}/bin before /usr/sbin in your PATH:

            PATH="#{HOMEBREW_PREFIX}/bin:$PATH"

      PHP#{php_version_path} Extensions will always be compiled against this PHP. Please install them using --without-homebrew-php to enable compiling against system PHP.
    EOS

    s.join "\n"
  end

  test do
    system "#{bin}/php -i"
  end
end
