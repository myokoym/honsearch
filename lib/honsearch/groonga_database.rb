# class Honsearch::GroongaDatabase
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

require "groonga"

module Honsearch
  class GroongaDatabase
    def initialize
      @database = nil
    end

    def open(base_path, encoding=:utf8)
      reset_context(encoding)
      path = File.join(base_path, "honsearch.db")
      if File.exist?(path)
        @database = Groonga::Database.open(path)
        populate_schema
      else
        FileUtils.mkdir_p(base_path)
        populate(path)
      end
      if block_given?
        begin
          yield(self)
        ensure
          close unless closed?
        end
      end
    end

    def delete(id_or_key_or_conditions)
      if id_or_key_or_conditions.is_a?(Integer)
        id = id_or_key_or_conditions
        books.delete(id, :id => true)
      elsif id_or_key_or_conditions.is_a?(String)
        key = id_or_key_or_conditions
        books.delete(key)
      elsif id_or_key_or_conditions.is_a?(Hash)
        conditions = id_or_key_or_conditions
        books.delete do |record|
          expression_builder = nil
          conditions.each do |key, value|
            case key
            when :resource_key
              record &= (record.resource._key == value)
            else
              raise ArgumentError,
                    "Not supported condition: <#{key}>"
            end
          end
          record
        end
      else
        raise ArgumentError,
              "Not supported type: <#{id_or_conditions.class}>"
      end
    end

    def unregister(title_or_url)
      resources.delete do |record|
        (record.title == title_or_url) |
        (record.xmlUrl == title_or_url)
      end
    end

    def close
      @database.close
      @database = nil
    end

    def closed?
      @database.nil? or @database.closed?
    end

    def authors
      @authors ||= Groonga["Authors"]
    end

    def publishers
      @publishers ||= Groonga["Publishers"]
    end

    def books
      @books ||= Groonga["Books"]
    end

    def pubyears
      @books ||= Groonga["Pubyears"]
    end

    def pubages
      @books ||= Groonga["Pubages"]
    end

    def db_path
      @database.path
    end

    private
    def reset_context(encoding)
      Groonga::Context.default_options = {:encoding => encoding}
      Groonga::Context.default = nil
    end

    def populate(path)
      @database = Groonga::Database.create(:path => path)
      populate_schema
    end

    def populate_schema
      Groonga::Schema.define do |schema|
        schema.create_table("Authors",
                            :type => :hash) do |table|
          table.short_text("name")
        end

        schema.create_table("Publishers",
                            :type => :hash) do |table|
          table.short_text("name")
        end

        schema.create_table("Pubyears",
                            :type => :hash) do |table|
        end

        schema.create_table("Pubages",
                            :type => :hash) do |table|
        end

        schema.create_table("CCode1Master",
                            :type => :hash) do |table|
          table.short_text("label")
        end
        schema.create_table("CCode2Master",
                            :type => :hash) do |table|
          table.short_text("label")
        end
        schema.create_table("CCode3Master",
                            :type => :hash) do |table|
          table.short_text("label")
        end
        schema.create_table("CCode4Master",
                            :type => :hash) do |table|
          table.short_text("label")
        end

        schema.create_table("Books",
                            :type => :hash) do |table|
          table.short_text("title")
          table.text("content")
          table.reference("authors", "Authors", type: :vector)
          table.reference("publisher", "Publishers")
          table.reference("pubyear", "Pubyears")
          table.reference("pubage", "Pubages")
          table.short_text("ccode")
          table.reference("ccode1", "CCode1Master")
          table.reference("ccode2", "CCode2Master")
          table.reference("ccode3", "CCode3Master")
          table.reference("ccode4", "CCode4Master")
        end

        schema.create_table("Terms",
                            :type => :patricia_trie,
                            :normalizer => "NormalizerAuto",
                            :default_tokenizer => "TokenBigram") do |table|
          table.index("Books.title")
          table.index("Books.content")
          table.index("Authors.name")
          table.index("Publishers.name")
        end

        schema.change_table("Authors") do |table|
          table.index("Books.authors")
        end
      end
    end
  end
end
