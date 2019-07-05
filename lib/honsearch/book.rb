module Honsearch
  class Book
    attr_reader :id
    attr_accessor :title
    attr_accessor :title_kana
    attr_accessor :subtitle
    attr_accessor :content
    attr_accessor :ndc
    attr_accessor :ndc1
    attr_accessor :ndc2
    attr_accessor :ndc3
    attr_accessor :orthography
    attr_accessor :copyrighted
    attr_accessor :published_date
    attr_accessor :updated_date
    attr_accessor :card_url
    attr_accessor :author_id
    attr_accessor :author_last_name
    attr_accessor :author_first_name
    attr_accessor :author_birthdate
    attr_accessor :author_botudate
    attr_accessor :first_edition_year
    attr_accessor :editor
    attr_accessor :proofreader
    attr_accessor :txt_url
    attr_accessor :txt_updated_date
    attr_accessor :html_url
    attr_accessor :html_updated_date
    attr_accessor :name
    attr_accessor :author_names
    attr_accessor :imprint_name
    attr_accessor :publisher_name
    def initialize(id)
      @id = id
      @author_names = []

      #@name = @title
      #unless @subtitle.empty?
      #  @name += " #{@subtitle}"
      #end
      #@author_name = [@author_last_name, @author_first_name].join

      #if /\ANDC (.*)/ =~ @classification
      #  @ndc = $1.split(/[[:space:]]/)
      #  @ndc1 = @ndc.map {|ndc| ndc[-3] + "00" }.uniq
      #  @ndc2 = @ndc.map {|ndc| ndc[-3..-2] + "0" }.uniq
      #  @ndc3 = @ndc.map {|ndc| ndc[-3..-1] }.uniq
      #  @kids = @ndc.any? {|ndc| /\AK/ =~ ndc }
      #end
    end

    def kids?
      @kids
    end

    class << self
      def parse_from_onix(onix)
        isbn = onix["RecordReference"]
        book = self.new(isbn)
        book.title = onix["DescriptiveDetail"]["TitleDetail"]["TitleElement"]["TitleText"]["content"]
        book.subtitle = onix["DescriptiveDetail"]["TitleDetail"]["TitleElement"]["Subtitle"]["content"]
        book.author_names = onix["DescriptiveDetail"]["Contributor"].map {|c| c["PersonName"]["content"].gsub(/\s/, "") }
        book.content = onix["CollateralDetail"]["TextContent"]
        book.imprint_name = onix["PublishingDetail"]["Imprint"]["ImprintName"]
        book.publisher_name = onix["PublishingDetail"]["Publisher"]
        book
      end
    end
  end
end
