
describe SourceMap::VLQ do

  before do
    def self.encode(x)
      SourceMap::VLQ.encode(x)
    end

    def self.decode(x)
      SourceMap::VLQ.decode(x)[0]
    end
  end

  it 'should be able to encode 0' do
    encode(0).should == 'A'
  end

  it 'should be able to decode 0' do
    decode('A').should == 0
  end

  it 'should be able to encode a positive integer' do
    encode(1).should == 'C'
    encode(2).should == 'E'
    encode(5).should == 'K'
    encode(1000).should == 'w+B'
    encode(100000).should == 'gqjG'
  end

  it 'should be able to decode a positive integer' do
    decode('C').should == 1
    decode('E').should == 2
    decode('K').should == 5
    decode('w+B').should == 1000
    decode('gqjG').should == 100000
  end

  it 'should be able to encode a negative integer' do
    encode(-1).should == 'D'
    encode(-2).should == 'F'
    encode(-5).should == 'L'
    encode(-1000).should == 'x+B'
    encode(-100000).should == 'hqjG'
  end

  it 'should be able to decode a negative integer' do
    decode('D').should == -1
    decode('F').should == -2
    decode('L').should == -5
    decode('x+B').should == -1000
    decode('hqjG').should == -100000
  end
end
