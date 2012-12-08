# -*- coding: utf-8 -*-
=begin
ファイルの情報をデータベースに格納するクラス

hash, path, size

=end

require 'rubygems'
require 'digest/md5'
require 'sqlite3'

class FileDB

  @db
  FILE_TABLE = "files"

  def initialize(file = "myfile.db")
    @db = SQLite3::Database.new(file)

    sql = <<SQL
create table if not exists #{FILE_TABLE} (
  id integer primary key,
  hash varchar(128),
  path varchar(255),
  size integer
);
SQL
    @db.execute(sql)
  end

  # 同じレコードが存在しなければ追加する
  def insert(path)
    insertsql = "insert into #{FILE_TABLE} values (:id, :hash, :path, :size)"
    hash = Digest::MD5.file(path).hexdigest()
    size = File::stat(path).size
    if !isRecorded(hash, path)
      record = { :hash => hash, :path => path, :size => size }
      @db.execute(insertsql, record)
      return true
    else
      return false
    end
  end

  # hash と path が同じなら同じファイルとして
  # ファイルが既に登録されているかどうかを調べる
  def isRecorded(hash, path)
    sql = "select path from #{FILE_TABLE} where hash = '#{hash}'"
    @db.execute(sql) { |row|
      if row[0] == path
        return true
      end
    }
    return false
  end

  # path の hash が同じファイルが登録されている場合は true
  def isDup(path)
    if not File.exists?(path)
      return false
    end
    hash = Digest::MD5.file(path).hexdigest()
    sql = "select count(*) from #{FILE_TABLE} where hash = '#{hash}'"
    @db.get_first_value(sql) != 0
  end

  def findDup
    dup = Hash.new
    sql = "select count(*), hash, path from #{FILE_TABLE} group by hash having count(*) > 1"
    @db.execute(sql) { |row|
      dup[row[1]] = 1
    }

    sizeorg = 0
    sizeall = 0
    n = 0
    dup.each { |d|
      #puts d[0]
      sql = "select hash, path, size from #{FILE_TABLE} where hash = '#{d[0]}'"
      n += 1
      size = 0
      @db.execute(sql) { |row|
        size = row[2]
        sizeall += size
      }
      sizeorg += size
    }
    puts "size total          = " + sizeall.to_s
    puts "size to be reduced  = " + (sizeall - sizeorg).to_s
    puts "the number of files = " + n.to_s
  end

  def totalSize
    sql = "select sum(size) from #{FILE_TABLE}"
    @db.get_first_value(sql)
  end

  def numFiles
    sql = "select count(*) from #{FILE_TABLE}"
    @db.get_first_value(sql)
  end
end
