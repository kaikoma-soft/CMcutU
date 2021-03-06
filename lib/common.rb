#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

require 'pp'
require 'optparse'
require 'fileutils'
require 'yaml'
require 'openssl'

require 'const.rb'

# def errLog( msg )             # dummy
#   puts( msg )
# end


def errLog( msg )

  if $cmcutLog != nil
    makePath( $cmcutLog )
    begin 
      File.open( $cmcutLog, "a" ) do |fp|
        fp.puts( msg )
      end
    rescue => e
      p $!
      puts e.backtrace.first + ": #{e.message} (#{e.class})"
      e.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
    end
  end

  puts( msg )
end


def makePath( path )
  dir = File.dirname( path )
  unless test( ?d, dir )
    puts( "makedir #{dir}" )
    FileUtils.mkpath( dir )
  end
end


#
#   スレッドの終了待ち合わせ
#
def waitThreads( threads )
  if threads.size > ( $max_threads - 1 )       # 終了待ち
    threads.shift.join
  end
end


#
#   タイムスタンプの比較
#
def oldFile?( fname, refTime )
  if test( ?f, fname )
    mtime = File.mtime( fname )
    if mtime < refTime
      return true
    end
  else
    return true
  end
  false
end

#
#  sha256 の計算
#
def fileDigest( fname )
  digest = OpenSSL::Digest.new("sha256")

  File.open(fname){|f|
    while data = f.read(1024)
      digest.update(data)
    end
  }
  digest.hexdigest
end


#
#  hash値の読み込み
#
def loadDigest( fname )
  if test( ?f, fname )
    File.open(fname) do |f|
      return f.gets.chomp
    end
  else
    return nil
  end
end


#
#  hash値の保存
#
def saveDigest( fname, str )
  dir = File.dirname( fname )
  if test( ?d, dir )
    File.open(fname,"w") do |f|
      f.puts( str )
    end
  else
    printf("dir not found %s\n",dir )
  end
end



module Common
  

  #
  #  秒から 0:00:00.00 形式に変換
  #
  def sec2min( sec )

    h    = ( sec / 3600 ).to_i
    sec2 = ( sec - h * 3600 ) 
    min  = ( sec2 / 60 ).to_i
    sec2 = sec2 - min * 60

    sprintf("%01d:%02d:%05.2f",h,min,sec2)
  end

  #
  #   CM の時間か(単体)
  #
  def cmTime?( dis, haba = 0.9 )
    [ 15.0, 30.0, 45.0, 60.0, 75.0, 90.0, 120.0 ].each do |cms|
      if dis.between?( cms - haba, cms + haba )
        return true
      end
    end
    return false
  end


  #
  #   CM の時間か(合計)
  #
  def cmTimeAll?( dis, haba = 0.9*2 )
    max = 15 * 4 * 8            # 最長 8分
    30.step( max, 15) do |cms|
      if dis.between?( cms - haba, cms + haba )
        return true
      end
    end
    return false
  end

  def num2ary( src )
    if src.class != Array
      tmp = []
      tmp << src if src != nil
      return tmp
    end
    src
  end

  def ary2num( src )
    if src.class == Array
      if src.size == 0
        return nil
      elsif src.size == 1
        return src[0]
      end
    end
    src
  end

  #
  #  logo ファイルテーブルの読み込み
  #
  def loadLogoTable()
    logotable = {}
    if test( ?f, Tablefn )
      logotable = YAML.load_file( Tablefn )
    end

    Dir.entries( TSdir ).each do |dir|
      next if dir == "." or dir == ".."
      path1 = TSdir + "/" + dir
      if test(?d, path1 )
        if logotable[ dir ] == nil
          Common::initLogoTable( dir, logotable )
        end
      end
    end

    logotable.keys.each do |dir|
      path1 = TSdir + "/" + dir
      unless test(?d, path1 )
        logotable.delete( dir )
      end
    end

    saveLogoTable( logotable )

    logotable
  end


  #
  #  logo ファイルテーブルの保存
  #
  def saveLogoTable( logotable )

    if logotable != nil
      # logotable.each_pair do |key,val|
      #   val[:duration] = ary2num( val[:duration] )
      #   val[:chapNum] = ary2num( val[:chapNum] )
      # end

      tmp = {}
      logotable.keys.sort.each do |key|
        tmp[ key ] = logotable[ key ]
      end

      File.open( Tablefn,"w") do |fp|
        fp.puts YAML.dump( tmp )
      end
    end
  end

  #
  #  空の値を設定
  #
  def initLogoTable( dir, logotable )
    if logotable[ dir ] == nil
      tmp = {}
      [ :logofn, :cmlogofn].each do |sym|
        tmp[ sym ] = nil 
      end
      tmp[ :position ] = "top-right" 
      tmp[ :chapNum ] = 10
      tmp[ :duration ] = 1440

      logotable[ dir ] = tmp
    end
  end


  
  module_function :sec2min
  module_function :saveLogoTable
  module_function :loadLogoTable
  module_function :initLogoTable
  module_function :num2ary
  module_function :ary2num
  
end

