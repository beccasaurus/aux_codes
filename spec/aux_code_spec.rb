require File.dirname(__FILE__) + '/spec_helper'

describe AuxCode do

  it 'should require a name' do
    AuxCode.create( :name => nil ).should_not be_valid
    AuxCode.create( :name => ' ' ).should_not be_valid
    AuxCode.create( :name => 'foo' ).should be_valid
  end

  it 'should have many aux codes (if category)' do
    code = AuxCode.create! :name => 'foo'
    code.codes.should be_empty
    w00t = code.codes.create :name => 'w00t'
    code.codes.should include(w00t)
  end
  
  it 'should have code names (if category)' do
    code = AuxCode.create! :name => 'foo'
    code.codes.create :name => 'chunky'
    code.codes.create :name => 'bacon'
    
    code.codes.length.should == 2
    code.code_names.length.should == 2
    code.code_names.should include('chunky')
    code.code_names.should include('bacon')
  end

  it "should know whether it's a category or a category value / code" do
    code = AuxCode.create! :name => 'foo'
    w00t = code.codes.create :name => 'w00t'

    w00t.is_a_category?.should be_false
    code.is_a_category?.should be_true
  end

  it 'should belong to a category (if not a category)' do
    code = AuxCode.create! :name => 'foo'
    w00t = code.codes.create :name => 'w00t'
    w00t.code.should == code
    w00t.category.should == code
    w00t.category.codes.should include(w00t)

    w00t.codes.should be_empty
    code.category.should be_nil
  end

  it 'should require a name unique to category' do
    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'

    first_category.aux_codes.create( :name => 'w00t' ).should be_valid
    first_category.aux_codes.create( :name => 'w00t' ).should_not be_valid
    second_category.aux_codes.create( :name => 'w00t' ).should be_valid
  end

  it 'should be able to easily get all categories' do
    AuxCode.categories.should be_empty

    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'w00t'

    AuxCode.categories.should include(first_category)
    AuxCode.categories.should include(second_category)
    AuxCode.categories.should_not include(code_1)
    AuxCode.categories.should_not include(code_2)
  end

  it 'should be able to easily get all category names' do
    AuxCode.category_names.should be_empty

    first_category  = AuxCode.create! :name => 'foo'
    second_category = AuxCode.create! :name => 'bar'
    code_1 = first_category.codes.create :name => 'w00t'

    AuxCode.category_names.should include('foo')
    AuxCode.category_names.should include('bar')
    AuxCode.category_names.should_not include('w00t')
  end

  it 'should be able to fetch a category give the category, its name, or its id' do
    cat  = AuxCode.create! :name => 'foo'
    AuxCode.category( cat ).should == cat
    AuxCode.category( cat.id ).should == cat
    AuxCode.category( cat.name ).should == cat
  end

  it 'should be able to easily get all values (codes) for a category' do
    first_category  = AuxCode.create! :name => 'foo'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'chunky'
    code_3 = first_category.codes.create :name => 'bacon'
    
    [ AuxCode.category_values( first_category ), AuxCode.category_values( 'foo' ) ].each do |codes|
      codes.should include(code_1)
      codes.should include(code_2)
      codes.should include(code_3)
      codes.should_not include(first_category)
    end
    AuxCode.category_values( first_category ).should == AuxCode.category_codes( first_category )
  end

  it 'should be able to easily get all value names (code names) for a category' do
    first_category  = AuxCode.create! :name => 'foo'
    code_1 = first_category.codes.create :name => 'w00t'
    code_2 = first_category.codes.create :name => 'chunky'
    code_3 = first_category.codes.create :name => 'bacon'
    
    [ AuxCode.category_code_names( first_category ), AuxCode.category_code_names( 'foo' ) ].each do |codes|
      codes.should include('w00t')
      codes.should include('chunky')
      codes.should include('bacon')
      codes.should_not include('foo')
    end
  end

  it 'should be able to get a Class for each category' do
    foo_category = AuxCode.create! :name => 'foo'
    foo_class = foo_category.aux_code_class
    foo_class.count.should == 0

    x = foo_category.codes.create :name => 'chunky'
    foo_class.count.should == 1

    foo_class.create :name => 'bacon'
    foo_class.count.should == 2

    foo = foo_class.create! :name => 'foo'
    foo_class.count.should == 3

    bar = foo_class.new :name => 'bar'
    bar.save
    foo_class.count.should == 4

    w00t = foo_class.new :name => 'w00t'
    w00t.save!
    foo_class.count.should == 5

    foo_class.find( :first, :conditions => ['name = ?', 'foo'] ).should == foo
    foo_class.find( :first, :conditions => ['name = ?', 'foo'] ).should_not == foo_category

    foo_class.find_by_name( 'foo' ).should == foo
    foo_class.find_by_name( 'foo' ).should_not == foo_category

    foo_class.find_all_by_name( 'foo' ).should include(foo)
    foo_class.find_all_by_name( 'foo' ).should_not include(foo_category)

    foo_class.all.should include(foo)
    foo_class.all.should_not include(foo_category)
  end

end
