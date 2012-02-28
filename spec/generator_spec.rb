describe SourceMap::Generator do
  before :all do
    class SourceMap
      public :mappings, :generated_line, :generated_col, :serialize_mapping
    end
  end
  describe '#add_mapping' do
    it 'should allow a mapping with no source data' do
      a = {:generated_line => 2, :generated_col => 1}
      SourceMap.new.tap{ |x| x.add_mapping(a) }.mappings.should == [a]
    end

    it 'should allow a mapping with source data' do
      a = {:generated_line => 2, :generated_col => 1,
           :source => "a.js", :source_line => 1, :source_col => 0}
      SourceMap.new.tap{ |x| x.add_mapping(a) }.mappings.should == [a]
    end

    it 'should allow a mapping with name and source data' do
      a = {:generated_line => 2, :generated_col => 1,
           :source => "a.js", :source_line => 1, :source_col => 0,
           :name => 'moo'}
      SourceMap.new.tap{ |x| x.add_mapping(a) }.mappings.should == [a]
    end

    it 'should disallow a mapping with no generated data' do
      a = {:source => "a.js", :source_line => 1, :source_col => 0}

      lambda{
        SourceMap.new.add_mapping(a)
      }.should raise_error(/generated_line/)

    end

    it 'should explain about invalid keys' do
      a = {:generated_line => 2, :generated_col => 1, :souce => 3}

      lambda{
        SourceMap.new.add_mapping(a)
      }.should raise_error(/souce/)
    end
  end

  describe '#add_generated' do
    it 'should work with no source information' do
      SourceMap.new.tap{ |x| x.add_generated('foo') }.mappings.should == [{
        :generated_line => 1,
        :generated_col => 0,
      }]
    end

    it 'should work with some source information' do
      SourceMap.new.tap{ |x| x.add_generated('foo', :source => 'a.js') }.mappings.should == [{
        :generated_line => 1,
        :generated_col => 0,
        :source => 'a.js',
        :source_line => 1,
        :source_col => 0
      }]
    end

    it 'should work with all source information' do
      SourceMap.new.tap{ |x| x.add_generated('foo', :source => 'a.js',
                                                    :source_line => 2,
                                                    :source_col => 2) }.mappings.should == [{
        :generated_line => 1,
        :generated_col => 0,
        :source => 'a.js',
        :source_line => 2,
        :source_col => 2
      }]
    end

    it 'should work with name information' do
      SourceMap.new.tap{ |x| x.add_generated('foo', :source => 'a.js', :name => 'fred') }.mappings.should == [{
        :generated_line => 1,
        :generated_col => 0,
        :source => 'a.js',
        :source_line => 1,
        :source_col => 0,
        :name => 'fred'
      }]
    end

    it 'should increment generated_col' do
      SourceMap.new.tap{ |x| x.add_generated('foo', :source => 'a.js', :name => 'fred') }.generated_col.should == 3
    end

    it 'should increated generated_line' do
      SourceMap.new.tap{ |x| x.add_generated("\nf\no\no", :source => 'a.js', :name => 'fred') }.generated_line.should == 4
    end

    it 'should start from the previous generated_col' do
      SourceMap.new.tap{ |x|
        x.add_generated('foo')
        x.add_generated("\nbar")
        x.add_generated('baz')
      }.mappings.should == [
        {:generated_line => 1, :generated_col => 0},
        {:generated_line => 2, :generated_col => 0},
        {:generated_line => 2, :generated_col => 3},
      ]
    end

    it 'should split multline fragments' do
      SourceMap.new.tap{ |x|
        x.add_generated("foo\nbarbaz\n")
      }.mappings.should == [
        {:generated_line => 1, :generated_col => 0},
        {:generated_line => 2, :generated_col => 0},
      ]
    end

    it 'should keep the source_line and source_col in sync with multiline fragments' do
      SourceMap.new.tap{ |x|
        x.add_generated("foo\nbarbaz\n", :source => 'a.js', :source_line => 10, :source_col => 6)
      }.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 10, :source_col => 6},
        {:generated_line => 2, :generated_col => 0, :source => 'a.js', :source_line => 11, :source_col => 0},
      ]
    end

    it 'should not move source_line and source_col if exact_position is given' do
      SourceMap.new.tap{ |x|
        x.add_generated("foo\nbarbaz\n", :source => 'a.js', :source_line => 10, :source_col => 6, :exact_position => true)
      }.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 10, :source_col => 6},
        {:generated_line => 2, :generated_col => 0, :source => 'a.js', :source_line => 10, :source_col => 6},
      ]
    end
  end

  describe '#generated_output' do
    it 'should be written to for each fragment' do
      map = SourceMap.new(:generated_output => (go = StringIO.new))
      map.generated_output.should == go

      go.should_receive(:<<).with('bananas')
      map.add_generated('bananas')

      go.should_receive(:<<).with('elephants')
      map.add_generated('elephants')
    end

    it 'should be written to once for multiline fragments' do
      map = SourceMap.new
      map.generated_output = StringIO.new
      map.generated_output.should_receive(:<<).with("bananas\nelephants\n")
      map.add_generated("bananas\nelephants\n")
    end
  end

  describe 'as_json' do

    it 'should by valid by default' do
      SourceMap.new.as_json.should == {
        'version' => 3,
        'file' => '',
        'sourceRoot' => '',
        'sources' => [],
        'names' => [],
        'mappings' => ''
      }
    end

    it 'should preserve source_root from constructor' do
      SourceMap.new(:source_root => "http://localhost/debug/").as_json['sourceRoot'].should == "http://localhost/debug/"
    end

    it 'should preserve file from constructor' do
      SourceMap.new(:file => 'a.js').as_json['file'].should == "a.js"
    end

    it 'should include each name exactly once' do
      map = SourceMap.new

      map.add_generated("foo\n", :source => 'a.js', :name => 'baa')
      map.add_generated("foo\n", :source => 'a.js', :name => 'baa')
      map.add_generated("foo\n", :source => 'a.js', :name => 'aab')
      map.add_generated("foo\n", :source => 'a.js', :name => 'baa')

      map.as_json['names'].should == ['baa', 'aab']
    end

    it 'should include each source exactly once' do
      map = SourceMap.new

      map.add_generated("foo\n", :source => 'a.js')
      map.add_generated("foo\n", :source => 'a.js')
      map.add_generated("foo\n", :source => 'b.js')
      map.add_generated("foo\n", :source => 'a.js')

      map.as_json['sources'].should == ['a.js', 'b.js']
    end

    it 'should have a semi-colon between every line' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 3, :generated_col =>0)
      map.add_mapping(:generated_line => 4, :generated_col =>0)
      map.add_mapping(:generated_line => 6, :generated_col =>0)

      map.as_json['mappings'].should == ';;A;A;;A'
    end

    it 'should have a comma between each fragment on the same line' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0)
      map.add_mapping(:generated_line => 1, :generated_col =>1)
      map.add_mapping(:generated_line => 1, :generated_col =>2)

      map.as_json['mappings'].should == 'A,C,C'
    end

    it 'should reset the vlq offset for the column when starting a new line' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0)
      map.add_mapping(:generated_line => 1, :generated_col =>1)
      map.add_mapping(:generated_line => 2, :generated_col =>2)

      map.as_json['mappings'].should == 'A,C;E'
    end

    it 'should encode source file positions relativesly' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 2, :generated_col =>0, :source => 'b.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 3, :generated_col =>0, :source => 'b.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 4, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1)

      map.as_json['mappings'].should == 'AAAA;ACAA;AAAA;ADAA'
    end

    it 'should encode source_line relatively (even when switching sources)' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 2, :generated_col =>0, :source => 'b.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 3, :generated_col =>0, :source => 'b.js', :source_col => 0, :source_line => 2)
      map.add_mapping(:generated_line => 4, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 4)

      map.as_json['mappings'].should == 'AAAA;ACAA;AACA;ADEA'
    end

    it 'should encode source_col relatively (ignoring changes to source and source_line)' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 2, :generated_col =>0, :source => 'b.js', :source_col => 5, :source_line => 1)
      map.add_mapping(:generated_line => 3, :generated_col =>0, :source => 'b.js', :source_col => 9, :source_line => 2)
      map.add_mapping(:generated_line => 4, :generated_col =>0, :source => 'a.js', :source_col => 2, :source_line => 4)

      map.as_json['mappings'].should == 'AAAA;ACAK;AACI;ADEP'
    end

    it 'should encode name positions relatively' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1, :name => 'a')
      map.add_mapping(:generated_line => 2, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 2, :name => 'b')
      map.add_mapping(:generated_line => 3, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 3, :name => 'b')
      map.add_mapping(:generated_line => 4, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 4, :name => 'a')

      map.as_json['mappings'].should == 'AAAAA;AACAC;AACAA;AACAD'
    end

    it 'should re-order mappings by line' do
      map = SourceMap.new

      # same mappings as 'should encode source_col relatively (ignoring changes to source and source_line)'
      map.add_mapping(:generated_line => 4, :generated_col =>0, :source => 'a.js', :source_col => 2, :source_line => 4)
      map.add_mapping(:generated_line => 1, :generated_col =>0, :source => 'a.js', :source_col => 0, :source_line => 1)
      map.add_mapping(:generated_line => 3, :generated_col =>0, :source => 'b.js', :source_col => 9, :source_line => 2)
      map.add_mapping(:generated_line => 2, :generated_col =>0, :source => 'b.js', :source_col => 5, :source_line => 1)

      map.as_json['mappings'].should == 'AAAA;ACAK;AACI;ADEP'
    end

    it 'should re-order fragments within a line if necessary' do
      map = SourceMap.new

      map.add_mapping(:generated_line => 1, :generated_col =>3)
      map.add_mapping(:generated_line => 1, :generated_col =>1)
      map.add_mapping(:generated_line => 1, :generated_col =>0)

      map.as_json['mappings'].should == 'A,C,E'
    end
  end

  it 'should pass the test from https://github.com/mozilla/source-map/blob/master/test/test-source-map-generator.js' do
    map = SourceMap.new(:file => 'min.js', :source_root => '/the/root')

    map.add_mapping(:generated_line => 1, :generated_col => 1, :source_line => 1, :source_col => 1, :source => 'one.js')
    map.add_mapping(:generated_line => 1, :generated_col => 5, :source_line => 1, :source_col => 5, :source => 'one.js')
    map.add_mapping(:generated_line => 1, :generated_col => 9, :source_line => 1, :source_col => 11, :source => 'one.js')
    map.add_mapping(:generated_line => 1, :generated_col => 18, :source_line => 1, :source_col => 21, :source => 'one.js', :name => 'bar')
    map.add_mapping(:generated_line => 1, :generated_col => 21, :source_line => 2, :source_col => 3, :source => 'one.js')
    map.add_mapping(:generated_line => 1, :generated_col => 28, :source_line => 2, :source_col => 10, :source => 'one.js', :name => 'baz')
    map.add_mapping(:generated_line => 1, :generated_col => 32, :source_line => 2, :source_col => 14, :source => 'one.js', :name => 'bar')
    map.add_mapping(:generated_line => 2, :generated_col => 1, :source_line => 1, :source_col => 1, :source => 'two.js')
    map.add_mapping(:generated_line => 2, :generated_col => 5, :source_line => 1, :source_col => 5, :source => 'two.js')
    map.add_mapping(:generated_line => 2, :generated_col => 9, :source_line => 1, :source_col => 11, :source => 'two.js')
    map.add_mapping(:generated_line => 2, :generated_col => 18, :source_line => 1, :source_col => 21, :source => 'two.js', :name => 'n')
    map.add_mapping(:generated_line => 2, :generated_col => 21, :source_line => 2, :source_col => 3, :source => 'two.js')
    map.add_mapping(:generated_line => 2, :generated_col => 28, :source_line => 2, :source_col => 10, :source => 'two.js', :name => 'n')


    map.as_json.should == {
      'version' => 3,
      'file' => 'min.js',
      'names' => ['bar', 'baz', 'n'],
      'sources' => ['one.js', 'two.js'],
      'sourceRoot' => '/the/root',
      'mappings' =>  'CAAC,IAAI,IAAM,SAAUA,GAClB,OAAOC,IAAID;CCDb,IAAI,IAAM,SAAUE,GAClB,OAAOA'
    }
  end
end
