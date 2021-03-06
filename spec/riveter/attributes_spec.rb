require 'spec_helper'

describe Riveter::Attributes do
  describe "class" do
    subject do
      # create an anonymous class
      Class.new().class_eval {
        include Riveter::Attributes

        def self.name
          'TestClass'
        end

        self
      }
    end

    describe ".attributes" do
      it { subject.attributes.should_not be_nil }
      it { subject.attributes.should be_a(Array) }

      it "each class has it's own set" do
        subject.attributes.should_not eq(TestClassWithAttributes.attributes)
      end
    end

    it_should_behave_like "an attribute", :string, 'A' do
      let(:assigned_value) { 'B' }
    end

    it_should_behave_like "an attribute", :text, 'B' do
      let(:assigned_value) { 'C' }
    end

    it_should_behave_like "an attribute", :integer, 1 do
      let(:assigned_value) { '2' }
      let(:expected_value) { 2 }

      describe "additional" do
        before do
          subject.attr_integer :an_attribute
        end
        let(:instance) { subject.new() }

        it { instance.should validate_numericality_of(:an_attribute) }
      end
    end

    it_should_behave_like "an attribute", :date, Date.new(2010, 1, 12) do
      let(:assigned_value) { '2010-01-13' }
      let(:expected_value) { Date.new(2010, 1, 13) }

      describe "additional" do
        before do
          subject.attr_date :an_attribute
        end
        let(:instance) { subject.new() }

        it { instance.should validate_timeliness_of(:an_attribute) }
      end
    end

    it_should_behave_like "an attribute", :date_range, Date.new(2010, 1, 12)..Date.new(2012, 1, 11) do
      describe "additional" do
        before do
          subject.attr_date_range :an_attribute
        end
        let(:instance) { subject.new() }

        it { instance.should validate_date_range_of(:an_attribute) }
        it { instance.should validate_timeliness_of(:an_attribute_from) }
        it { instance.should validate_timeliness_of(:an_attribute_to) }

        it { instance.should respond_to(:an_attribute_from?) }

        it {
          instance.an_attribute = nil
          instance.an_attribute_from?.should be_false
        }

        it {
          instance.an_attribute_from = Date.today
          instance.an_attribute_from?.should be_true
        }

        it { instance.should respond_to(:an_attribute_to?) }

        it {
          instance.an_attribute = nil
          instance.an_attribute_to?.should be_false
        }

        it {
          instance.an_attribute_to = Date.today
          instance.an_attribute_to?.should be_true
        }
      end
    end

    it_should_behave_like "an attribute", :time, Time.new(2010, 1, 12, 8, 4, 45) do
      let(:assigned_value) { '2010-01-12 08:04:12' }
      let(:expected_value) { Time.new(2010, 1, 12, 8, 4, 12) }

      describe "additional" do
        before do
          subject.attr_time :an_attribute
        end
        let(:instance) { subject.new() }

        it { instance.should validate_timeliness_of(:an_attribute) }
      end
    end

    it_should_behave_like "an attribute", :boolean, true do
      let(:assigned_value) { '0' }
      let(:expected_value) { false }
    end

    it_should_behave_like "an attribute", :enum, TestEnum::Member1, TestEnum do
      let(:assigned_value) { 'Member2' }
      let(:expected_value) { TestEnum::Member2 }

      describe "additional" do
        before do
          subject.attr_enum :product_type, TestEnum, :required => true
        end
        let(:instance) { subject.new() }

        it { instance.should ensure_inclusion_of(:product_type).in_array(TestEnum.values) }

        it { should respond_to(:product_type_enum)}
        it { subject.product_type_enum.should eq(TestEnum) }
        it { should respond_to(:product_types)}
        it { subject.product_types.should eq(TestEnum.collection)}
      end
    end

    it_should_behave_like "an attribute", :array, [1, 2, 3] do
      let(:assigned_value) { %w(5 6 7) }
      let(:expected_value) { [5, 6, 7] }
    end

    it_should_behave_like "an attribute", :hash, {:a => :b} do
      let(:assigned_value) { {:c => '1', :d => '2'} }
      let(:expected_value) { {:c => 1, :d => 2} }
    end

    it_should_behave_like "an attribute", :model, TestModel.new(), TestModel do
      let(:assigned_value) { TestModel.new() }

      before do
        allow_any_instance_of(TestModel).to receive(:valid?) { true }
        allow(TestModel).to receive(:find_by)
      end

      describe "additional" do
        before do
          subject.attr_model :product, TestModel, :required => true
        end

        it { should respond_to(:product_model)}
        it { subject.product_model.should eq(TestModel) }

        it {
          allow(TestModel).to receive(:find_by).with(:id => 1) { assigned_value }

          instance = subject.new()
          instance.product = 1
          instance.product.should eq(assigned_value)
        }

        it {
          allow(TestModel).to receive(:find_by).with(:id => 1) { assigned_value }
          expect(assigned_value).to receive(:valid?) { true }

          instance = subject.new()
          instance.product = 1
          instance.valid?
        }
      end
    end

    it_should_behave_like "an attribute", :object, Object.new() do
      let(:assigned_value) { Object.new() }
    end
  end

  describe "instance" do
    subject { TestClassWithAttributes.new() }

    describe "#initialize" do
      it "assigns attribute default values" do
        subject.string.should eq('A')
        subject.text.should eq('b')
        subject.integer.should eq(1)
        subject.decimal.should eq(9.998)
        subject.date.should eq(Date.new(2010, 1, 12))
        subject.date_range.should eq(Date.new(2010, 1, 12)..Date.new(2011, 1, 12))
        subject.date_range_from.should eq(Date.new(2010, 1, 12))
        subject.date_range_to.should eq(Date.new(2011, 1, 12))
        subject.time.should eq(Time.new(2010, 1, 12, 14, 56))
        subject.boolean.should eq(true)
        subject.enum.should eq(TestEnum::Member1)
        subject.array.should eq([1, 2, 3])
        subject.hash.should eq({:a => :b})
        subject.model.should eq(TestModel)
        subject.object.should eq('whatever')
      end
    end

    describe "#attributes" do
      it { subject.attributes.should_not be_nil }
      it { subject.attributes.should be_a(Hash) }
      it {
        subject.attributes.should eq({
          'string' => 'A',
          'text' => 'b',
          'integer' => 1,
          'decimal' => 9.998,
          'date' => Date.new(2010, 1, 12),
          'date_range' => Date.new(2010, 1, 12)..Date.new(2011, 1, 12),
          'date_range_from' => Date.new(2010, 1, 12),
          'date_range_to' => Date.new(2011, 1, 12),
          'time' => Time.new(2010, 1, 12, 14, 56),
          'boolean' => true,
          'enum' => TestEnum::Member1,
          'array' => [1, 2, 3],
          'hash' => {:a => :b},
          'model' => TestModel,
          'object' => 'whatever'
        })
      }
    end

    describe "#persisted?" do
      it { subject.persisted?.should be_false }
    end

    describe "#column_for_attribute" do
      it { subject.column_for_attribute(:string).should_not be_nil }
      it { subject.column_for_attribute(:string).name.should eq(:string) }
    end

    describe "#filter_params" do
      it "filters out unknown attributes" do
        params = subject.send(:filter_params, :string => 'AA', :unknown => :value)
        params.should include(:string)
        params.should_not include(:unknown)
      end
    end

    describe "#clean_params" do
      it "removes blank attributes" do
        params = subject.send(:clean_params, :string => '')
        params.should_not include(:string)
      end

      it "removes nil attributes" do
        params = subject.send(:clean_params, :string => nil)
        params.should_not include(:string)
      end

      describe "nested attribute arrays" do
        it "removes blank attributes" do
          params = subject.send(:clean_params, :string => [1, 2, ''])
          params.should include(:string)
          params[:string].length.should eq(2)
        end

        it "removes nil attributes" do
          params = subject.send(:clean_params, :string => [1, 2, nil])
          params.should include(:string)
          params[:string].length.should eq(2)
        end
      end

      describe "nested attribute hashes" do
        it "removes blank attributes" do
          params = subject.send(:clean_params, :string => { :a => 'A', :b => '' })
          params.should include(:string)
          params[:string].should_not include(:b)
        end

        it "removes nil attributes" do
          params = subject.send(:clean_params, :string => { :a => 'A', :b => nil })
          params.should include(:string)
          params[:string].should_not include(:b)
        end
      end
    end

    describe "#apply_params" do
      it "assigns attributes" do
        subject.string.should eq('A')
        subject.send(:apply_params, :string => 'test')
        subject.string.should eq('test')
      end

      it "raises UnknownAttributeError for unknown attribute" do
        expect {
          subject.send(:apply_params, :unknown => 'test')
        }.to raise_error(Riveter::UnknownAttributeError)
      end

      it "re-raises error attribute" do
        allow(subject).to receive(:string=).and_raise(ArgumentError)
        expect {
          subject.send(:apply_params, :string => 'test')
        }.to raise_error(ArgumentError)
      end
    end
  end
end
