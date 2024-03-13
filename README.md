# LibArchive.jl: A Julia interface for libarchive

[![Build status](https://github.com/yuyichao/LibArchive.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/yuyichao/LibArchive.jl/actions/workflows/CI.yml)
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
