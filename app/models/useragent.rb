class Useragent < ActiveRecord::Base

  BROWSER_TYPES = %w(popular gbs beta mobile).freeze

  has_many :useragent_runs
  has_many :clients

  validates :name,    :presence => true, :uniqueness => true
  validates :engine,  :presence => true
  validates :version, :presence => true, :uniqueness => { :scope => :engine }

  scope :active,  where(:active => true)
  BROWSER_TYPES.each{|b| scope b, where(b => true) }
  scope :with_browser, lambda{|browserstr|
    sql = []; params = []
    BROWSER_TYPES.select{|b| (browserstr || '').include?(b) }.each{|b| sql << "#{b} = ?"; params << true }
    sql.empty? ? where("1 = 0") : where(sql.join(" OR "), *params)
  }

  class << self

    def parse(str)
      dstr = str.downcase

      version = case dstr
        when /.*(webos|fennec|series60|blackberry[0-9]*[a-z]*)[\/: ]([0-9a-z.]+)/ then $2
        when /.+(rv|applewebkit|presto|msie|konqueror)[\/: ]([0-9a-z.]+)/         then $2
        else                                                                      "unknown"
      end

      browser = case dstr
        when /msie.*windows phone/    then "winmo"
        when /msie/                   then "msie"
        when /konqueror/              then "konqueror"
        when /chrome/                 then "chrome"
        when /webos/                  then "webos"
        when /android.*mobile safari/ then "android"
        when /series60/               then "s60"
        when /blackberry/             then "blackberry"
        when /opera mobi/             then "operamobile"
        when /fennec/                 then "fennec"
        when /webkit.*mobile/         then "mobilewebkit"
        when /webkit/                 then "webkit"
        when /presto/                 then "presto"
        when /gecko/                  then "gecko"
        else                               "unknown"
      end

      os = case dstr
        when /windows nt 6\.1/ then "win7"
        when /windows nt 6\.0/ then "vista"
        when /windows nt 5\.2/ then "2003"
        when /windows nt 5\.1/ then "xp"
        when /windows nt 5\.0/ then "2000"
        when /blackberry/      then "blackberry"
        when /iphone/          then "iphone"
        when /ipod/            then "ipod"
        when /ipad/            then "ipad"
        when /symb/            then "symbian"
        when /webos/           then "webos"
        when /android/         then "android"
        when /windows phone/   then "winmo"
        when /os x 10[\._]4/   then "osx10.4"
        when /os x 10[\._]5/   then "osx10.5"
        when /os x 10[\._]6/   then "osx10.6"
        when /os x/            then "osx"
        when /linux/           then "linux"
        else                        "unknown"
      end

      { :browser => browser, :version => version, :os => os }
    end

    def find_by_useragent(str_or_hash)
      ua = str_or_hash.is_a?(Hash) ? str_or_hash : parse(str_or_hash)

      if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'mysql'
        # This assumes that the greatest alphabetical name will be the greatest version
        self.where("engine=? AND ? REGEXP version", ua[:browser], ua[:version]).order("name DESC").first
      else
        self.where(:engine => ua[:browser]).order("name DESC").detect{|u| ua[:version] =~ Regexp.new(u.version) }
      end
    end

  end

end
