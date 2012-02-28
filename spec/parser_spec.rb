describe SourceMap::Parser do

  describe '.from_json' do
    it "should copy across the file" do
      SourceMap.from_json('version' => 3, 'file' => 'foo.js').file.should == 'foo.js'
    end

    it "should copy across the sourceRoot" do
      SourceMap.from_json('version' => 3, 'sourceRoot' => 'http://example.com/').source_root.should == 'http://example.com/'
    end

    it "should copy across the sources" do
      SourceMap.from_json('version' => 3, 'sources' => ['a.js', 'b.js']).sources.should == ['a.js', 'b.js']
    end

    it "should copy across the names" do
      SourceMap.from_json('version' => 3, 'names' => ['a', 'b', 'c']).names.should == ['a', 'b', 'c']
    end
  end

  describe '#parse_mappings' do
    it 'should pass through to #parse_mapping with the correct line number' do
      map = SourceMap.new

      map.should_receive(:parse_mapping).with('A', 1).and_return({:generated_line => 1, :generated_col => 1})
      map.should_receive(:parse_mapping).with('C', 1).and_return({:generated_line => 2, :generated_col => 1})
      map.should_receive(:parse_mapping).with('E', 2).and_return({:generated_line => 3, :generated_col => 1})
      map.should_receive(:parse_mapping).with('G', 4).and_return({:generated_line => 4, :generated_col => 1})
      map.should_receive(:parse_mapping).with('H', 5).and_return({:generated_line => 5, :generated_col => 1})

      map.parse_mappings('A,C;E;;G,;H')
    end
  end

  describe '#parse_mapping' do
    it 'should parse the generated_col' do
      map = SourceMap.new

      map.parse_mappings('E')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 2}
      ]
    end

    it 'should append to map.mappings' do
      map = SourceMap.new

      map.parse_mappings('A;E')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0},
        {:generated_line => 2, :generated_col => 2}
      ]
    end

    it 'should sort the segments on a line ascendingly' do
      map = SourceMap.new

      map.parse_mappings('E,F')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0},
        {:generated_line => 1, :generated_col => 2}
      ]
    end

    it 'should parse the source name' do
      map = SourceMap.new(:sources => ['a.js', 'b.js'])

      map.parse_mappings('AAAA;ACAA')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 0},
        {:generated_line => 2, :generated_col => 0, :source => 'b.js', :source_line => 1, :source_col => 0}
      ]
    end

    it 'should parse the source line' do
      map = SourceMap.new(:sources => ['a.js', 'b.js'])

      map.parse_mappings('AACA;AADA')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 2, :source_col => 0},
        {:generated_line => 2, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 0}
      ]
    end

    it 'should parse the source cols' do
      map = SourceMap.new(:sources => ['a.js', 'b.js'])

      map.parse_mappings('AAAE;AAAS')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 2},
        {:generated_line => 2, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 11}
      ]
    end

    it 'should parse the names' do
      map = SourceMap.new(:names => ['d', 'e'], :sources => ['a.js'])

      map.parse_mappings('AAAAC;AAAAD')

      map.mappings.should == [
        {:generated_line => 1, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 0, :name => 'e'},
        {:generated_line => 2, :generated_col => 0, :source => 'a.js', :source_line => 1, :source_col => 0, :name => 'd'}
      ]
    end

    it 'should raise an error on an unknown source' do
      map = SourceMap.new(:sources => ['a.js'], :file => 'moo.js')

      lambda{
        map.parse_mappings(';AEAA')
      }.should raise_error(/In map for moo.js:2: unknown source id: 2/)
    end

    it 'should raise an error on negative sources' do
      map = SourceMap.new(:sources => ['a.js'], :file => 'moo.js')

      lambda{
        map.parse_mappings('ADAA')
      }.should raise_error(/In map for moo.js:1: unknown source id: -1/)
    end

    it 'should raise an error on the zeroth source lines' do
      map = SourceMap.new(:sources => ['a.js'], :file => 'moo.js')

      lambda{
        map.parse_mappings('AADA')
      }.should raise_error(/In map for moo.js:1: unexpected source_line: 0/)

    end
  end

  it 'should be able to parse the example from mozilla/source-map' do

    map  = {
      :version => 3,
      :file => 'min.js',
      :names => ['bar', 'baz', 'n'],
      :sources => ['one.js', 'two.js'],
      :sourceRoot => '/the/root',
      :mappings => 'CAAC,IAAI,IAAM,SAAUA,GAClB,OAAOC,IAAID;CCDb,IAAI,IAAM,SAAUE,GAClB,OAAOA'
    }.to_json

    SourceMap.from_s(map).mappings.should == [
      {:generated_line => 1, :generated_col => 1, :source => 'one.js', :source_line => 1, :source_col => 1},
      {:generated_line => 1, :generated_col => 5, :source => 'one.js', :source_line => 1, :source_col => 5},
      {:generated_line => 1, :generated_col => 9, :source => 'one.js', :source_line => 1, :source_col => 11},
      {:generated_line => 1, :generated_col => 18, :source => 'one.js', :source_line => 1, :source_col => 21, :name => 'bar'},
      {:generated_line => 1, :generated_col => 21, :source => 'one.js', :source_line => 2, :source_col => 3},
      {:generated_line => 1, :generated_col => 28, :source => 'one.js', :source_line => 2, :source_col => 10, :name => 'baz'},
      {:generated_line => 1, :generated_col => 32, :source => 'one.js', :source_line => 2, :source_col => 14, :name => 'bar'},
      {:generated_line => 2, :generated_col => 1, :source => 'two.js', :source_line => 1, :source_col => 1},
      {:generated_line => 2, :generated_col => 5, :source => 'two.js', :source_line => 1, :source_col => 5},
      {:generated_line => 2, :generated_col => 9, :source => 'two.js', :source_line => 1, :source_col => 11},
      {:generated_line => 2, :generated_col => 18, :source => 'two.js', :source_line => 1, :source_col => 21, :name => 'n'},
      {:generated_line => 2, :generated_col => 21, :source => 'two.js', :source_line => 2, :source_col => 3},
      {:generated_line => 2, :generated_col => 28, :source => 'two.js', :source_line => 2, :source_col => 10, :name => 'n'},
    ]

  end

end
