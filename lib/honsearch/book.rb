module Honsearch
  class Book
    attr_reader :id
    attr_accessor :title
    attr_accessor :subtitle
    attr_accessor :content
    attr_accessor :author_names
    attr_accessor :publisher_name
    attr_accessor :pubyear
    attr_accessor :pubage
    attr_accessor :ccode
    attr_accessor :ccode1
    attr_accessor :ccode2
    attr_accessor :ccode3
    attr_accessor :ccode4
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
        #p [summary["pubdate"], onix["PublishingDetail"]["PublishingDate"], openbd_book["hanmoto"]["dateshuppan"]]
        unless summary["pubdate"].empty?
          pubdate = summary["pubdate"].gsub(/[A-z]/, "")
          if pubdate.include?("-")
            year = pubdate.split("-")[0]
          else
            year = pubdate[0, 4]
          end
          if /\A210/ =~ year
            year = "201#{year[3]}"
          elsif /\A1[0-5]/ =~ year
            year = "20#{year[0, 2]}"
          end
          if /\A[12]\d{3}\z/ =~ year
            book.pubyear = year
            book.pubage = "#{year[0, 3]}0"
          end
        end
        if onix["DescriptiveDetail"]["Subject"]
          ccode = onix["DescriptiveDetail"]["Subject"].select {|subject|
            subject["SubjectSchemeIdentifier"] == "78"
          }.first["SubjectCode"]
          if ccode
            book.ccode = ccode
            book.ccode1 = ccode[0]
            if book.ccode1 == "4"
              book.ccode1 = "8" # ISBN: 9784034396407
            end
            book.ccode2 = ccode[1]
            book.ccode3 = ccode[2] + "0"
            book.ccode4 = ccode[2, 2]
          end
        end
        #hanmoto = openbd_book["hanmoto"]
        #ndc = hanmoto["ndccode"]
        #book.ndc1 = ndc[-3] + "00"
        #book.ndc2 = ndc[-3..-2] + "0"
        #book.ndc3 = ndc[-3..-1]
        #book.genrecodetrc = hanmoto["genrecodetrc"]
        #book.genrecodetrcjidou = hanmoto["genrecodetrcjidou"]
        #book.zasshicode = hanmoto["zasshicode"]
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
