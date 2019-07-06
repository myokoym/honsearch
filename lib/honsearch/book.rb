module Honsearch
  class Book
    attr_reader :id
    attr_accessor :title
    attr_accessor :subtitle
    attr_accessor :content
    attr_accessor :author_names
    attr_accessor :publisher_name
    attr_accessor :pubyear
    def initialize(id)
      @id = id
      @author_names = []
    end

    class << self
      def parse_from_onix(openbd_book)
        onix = openbd_book["onix"]
        isbn = onix["RecordReference"]
        book = self.new(isbn)
        book.title = onix["DescriptiveDetail"]["TitleDetail"]["TitleElement"]["TitleText"]["content"]
        if onix["DescriptiveDetail"]["TitleDetail"]["TitleElement"]["Subtitle"]
          book.subtitle = onix["DescriptiveDetail"]["TitleDetail"]["TitleElement"]["Subtitle"]["content"]
        end
        if onix["DescriptiveDetail"]["Contributor"] &&
           onix["DescriptiveDetail"]["Contributor"][0]["PersonName"]
          book.author_names = onix["DescriptiveDetail"]["Contributor"].map {|c| c["PersonName"]["content"].gsub(/[\s　]/, "") }
        #else
        #  p onix["DescriptiveDetail"]
        end
        if onix["CollateralDetail"]["TextContent"]
          book.content = onix["CollateralDetail"]["TextContent"].map {|c| c["Text"] }.join("\n")
        end
        book.publisher_name = onix["PublishingDetail"]["Imprint"]["ImprintName"]
        summary = openbd_book["summary"]
        unless summary["pubdate"].empty?
          pubdate = summary["pubdate"].gsub(/[A-z]/, "")
          if pubdate.include?("-")
            year = pubdate.split("-")[0]
          else
            year = pubdate[0, 4]
          end
          if /\A[12]\d{3}\z/ =~ year
            book.pubyear = year
          end
        end
        book
      end

      def parse_from_summary(summary)
        isbn = summary["isbn"]
        book = self.new(isbn)
        book.title = summary["title"]
        book.publisher = summary["publisher"]
        book.author = summary["author"] # TODO: multi author
      end
    end
  end
end
