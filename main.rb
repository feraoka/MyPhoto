# -*- coding: utf-8 -*-
require 'find'
require 'imagefiledb.rb'
require 'optparse'

dbfile = 'moved.db'

conf = Hash.new

OptionParser.new do |opt|
  opt.on('-s path', 'source directory') { |v| conf[:s] = v }
  opt.on('-d path', 'destination directory') { |v| conf[:d] = v }
  opt.on('-v', 'dry run') { |v| conf[:v] = v }
  opt.on('-c', 'copy rather than move') { |v| conf[:c] = c }
  opt.version = '1.00'
  opt.parse!(ARGV)

  if conf[:s] == nil or conf[:d] == nil or
      not FileTest.directory?(conf[:s]) or
      not FileTest.directory?(conf[:d])
    puts opt.help
    exit
  end
end

srctop = File::expand_path(conf[:s])
dsttop = File::expand_path(conf[:d])

db = ImageFileDB.new(dsttop + File::SEPARATOR + dbfile)

Find.find(srctop) do |file|
  next if File.directory?(file)
  filename = db.filename(file)
  next if filename == nil

  year = db.year(filename)
  month = db.month(filename)
  dst = dsttop + File::SEPARATOR + year
  if not File.exists?(dst)
    Dir.mkdir(dst)
  end
  dst += File::SEPARATOR + month
  if not File.exists?(dst)
    Dir.mkdir(dst)
  end
  dst += File::SEPARATOR + db.filename(file)

  if not db.isDup(dst)

    if File.exists?(dst)
      dst = db.uniqueFile(dst)
    end
    if (conf[:v])
      # dry run
      puts "will move from #{file} to #{dst}"
    else
      if (conf[:c])
        puts "copied from #{file} to #{dst}"
        FileUtils.copy_file(file, dst, true)
      else
        puts "moved from #{file} to #{dst}"
        FileUtils.move(file, dst)
      end
      db.insert(dst)
    end
  else
    puts "WARNING: #{file} already exists at #{dst}"
  end
end
