# LibArchive.jl: A Julia interface for libarchive

[![Build Status](https://travis-ci.org/yuyichao/LibArchive.jl.svg?branch=master)](https://travis-ci.org/yuyichao/LibArchive.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/05a3b69ak67uyoyr/branch/master?svg=true)](https://ci.appveyor.com/project/yuyichao/libarchive-jl/branch/master)
[![codecov.io](http://codecov.io/github/yuyichao/LibArchive.jl/coverage.svg?branch=master)](http://codecov.io/github/yuyichao/LibArchive.jl?branch=master)

## Usage

read a binary file with lzma compression
```
reader = LibArchive.Reader(filename)
LibArchive.support_format_raw(reader)
LibArchive.support_filter_all(reader)
entry = LibArchive.next_header(reader)
arr = read(reader)
close(reader)
```
