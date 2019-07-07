# class Honsearch::Loader
#
# Copyright (C) 2016  Masafumi Yokoyama <myokoym@gmail.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "openbd"
require "parallel"
require "honsearch/groonga_database"
require "honsearch/book"

module Honsearch
  class Loader
    def load(options={})
      client = Openbd::Client.new
      #isbns = client.coverage
      #File.open("isbns.json", "w") do |file|
      #  JSON.dump(isbns, file)
      #end
      isbn_all = JSON.parse(File.read("isbns.json"))
      #src_books = JSON.parse(File.read("books.json"))
      #src_books = client.get(isbns.last(500))
      #File.open("books.json", "w") do |file|
      #  JSON.dump(src_books, file)
      #end
      isbn_all.select {|isbn| isbn.start_with?("9784") }.each_slice(500) do |isbns|
        books = []
        client.get(isbns).each do |openbd_book|
          begin
            books << Book.parse_from_onix(openbd_book)
          rescue NoMethodError, TypeError => e
            p openbd_book
            puts e.message
            puts e.backtrace
          end
        end

        load_proc = lambda do |book|
          load_book(book, options)
        end

        if options[:parallel]
          Parallel.each(books, &load_proc)
        else
          books.each(&load_proc)
        end
        sleep 10
      end
    end

    private
    def load_book(book, options={})
      if options[:diff]
        updated_date = [book.published_date, book.updated_date].max
        return if updated_date < options[:diff]
      end

      if Groonga["Books"][book.id]
        authors = Groonga["Books"][book.id].authors
      else
        authors = []
      end
      book.author_names.each do |author_name|
        author = Groonga["Authors"][author_name]
        unless author
          author = Groonga["Authors"].add(
            author_name,
            name: author_name
          )
        end
        authors << author
      end
      if book.publisher_name
        publisher = Groonga["Publishers"][book.publisher_name]
        unless publisher
          publisher = Groonga["Publishers"].add(
            book.publisher_name,
            name: book.publisher_name
          )
        end
      end
      if book.pubyear
        pubyear = Groonga["Pubyears"][book.pubyear]
        unless pubyear
          pubyear = Groonga["Pubyears"].add(
            book.pubyear,
          )
        end
      end
      if book.pubage
        pubage = Groonga["Pubages"][book.pubage]
        unless pubage
          pubyear = Groonga["Pubages"].add(
            book.pubage,
          )
        end
      end

      Groonga["Books"].add(
        book.id,
        title: book.title,
        subtitle: book.subtitle,
        content: book.content,
        authors: authors.uniq,
        publisher: publisher,
        pubyear: pubyear,
        pubage: pubage,
        ccode: book.ccode,
        ccode1: book.ccode1,
        ccode2: book.ccode2,
        ccode3: book.ccode3,
        ccode4: book.ccode4,
      )
    end
  end
end
