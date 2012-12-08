# -*- coding: utf-8 -*-
require 'rubygems'
require 'exifr'
require 'time'
require 'date'
require 'fileutils'
require 'filedb.rb'

class ImageFileDB < FileDB

  IMAGE_EXTENSION = [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tif", ".mp4", ".mpg", ".avi", ".wav"]

  def insert(path)
    path = File.expand_path(path)
    Find.find(path) do |child|
      p child
      next if File.directory?(child)
      ext = File.extname(child).downcase
      if IMAGE_EXTENSION.index(ext)
        super(child)
      else
        puts "WARNING: #{child} is not an image file (insert)"
      end
    end
  end

  # time から作成するファイル名
  def timetofile(time)
    time.strftime("%Y-%m-%d %H.%M.%S")
  end

  def filename(path)
    ext = File.extname(path).downcase
    if IMAGE_EXTENSION.index(ext) != nil
      begin
        name = timetofile(EXIFR::JPEG::new(path).date_time_original)
      rescue
        name = timetofile(File::stat(path).mtime)
      end
      name + ext
    else
      puts "WARNING: #{path} is not an image file (filename)"
      nil
    end
  end

  def uniqueFile(path)
    pattern = /^(\d\d\d\d-\d\d-\d\d \d\d\.\d\d\.\d\d)(-([0-9]*))*(\.\w+)$/
    path = File.basename(path)
    while File.exists?(path)
      if pattern =~ path
        if $3 == nil
          n = 0
        else
          n = $3.to_i
        end
        path = $1 + "-" + (n + 1).to_s + $4
      else
        puts "ERROR: internal error when creating filename for #{path}"
        exit
      end
    end
    puts "NOTE: found a same file name. created #{path}"
    path
  end

  # HACK 拡張番号と拡張子
  FILE_PATTERN = /^(\d\d\d\d)-(\d\d)/

  def year(filename)
    FILE_PATTERN =~ filename
    $1
  end

  def month(filename)
    FILE_PATTERN =~ filename
    $2
  end
end
