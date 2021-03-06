require 'spec_helper'

describe Device do

  it { should validate_presence_of :resource_owner_id }
  it { should validate_presence_of :name }
  it { should validate_presence_of :maker_id }

  its(:pending) { should == false }

  it_behaves_like 'a boolean' do
    let(:field)       { 'pending' }
    let(:accepts_nil) { 'false' }
    let(:resource)    { FactoryGirl.create :device }
  end

  describe '#type_id' do

    let(:resource) { FactoryGirl.create :device }
    let(:type)     { Type.find resource.type_id }

    it 'sets the type_id field' do
      resource.type_id.should == type.id
    end
  end

  describe '#physical' do

    let(:resource) { FactoryGirl.create :device }

    it 'sets the physical uri' do
      resource.physical['uri'].should == "http://arduino.casa.com/#{resource.id}"
    end

    describe 'when delete the physical' do

      before { resource.update_attributes(physical: { uri: '' }) }

      it 'sets #physical to nil' do
        resource.physical.should be_nil
      end
    end
  end

  describe '#activation_code' do

    let(:resource) { FactoryGirl.create :device }

    it 'sets the activation_code field' do
      resource.activation_code.should == Signature.sign(resource.id, resource.secret)
    end
  end

  describe '#category' do

    let(:resource) { FactoryGirl.create :device }

    it 'sets the category field' do
      resource.category.should == 'lights'
    end
  end

  describe '#set_type_properties' do

    let(:resource) { FactoryGirl.create :device }

    describe 'when creates a resource' do

      it 'connects two properties' do
        resource.properties.should have(2).items
      end

      describe 'with status' do

        subject { resource.properties.first }

        its(:value)       { should == 'off' }
        its(:expected)    { should == 'off' }
        its(:pending)     { should == false }
        its(:property_id) { should_not be_nil }
        its(:id)          { should == resource.properties.first.property_id }
      end

      describe 'with intensity' do

        subject { resource.properties.last }

        its(:value)       { should == '0' }
        its(:expected)    { should == '0' }
        its(:pending)     { should == false }
        its(:property_id) { should_not be_nil }
        its(:id)          { should == resource.properties.last.property_id }
      end
    end

    describe 'when updates the resource properties' do

      describe 'when updates the status value' do
        let(:properties) { [ { id: resource.properties.first.id, value: 'value', expected: 'expected', pending: false, accepted: { 'updated' => 'updated' } } ] }

        before  { resource.update_attributes(properties_attributes: properties) }

        it 'updates its value' do
          resource.properties.first.value.should == 'value'
        end

        it 'updates its pending status' do
          resource.properties.first.pending.should == false
        end

        it 'updates its accepted values' do
          resource.properties.first.accepted.should == { 'updated' => 'updated' }
        end

        it 'does not create new properties' do
          resource.properties.should have(2).items
        end
      end

      describe 'when updates a not existing property' do
        let(:properties) { [ { id: Settings.resource_id, value: 'on'} ] }
        let(:update)     { resource.properties_attributes = properties }

        it 'raises a not found error' do
          expect { update }.to raise_error Mongoid::Errors::DocumentNotFound
        end
      end
    end
  end

  describe 'when updates the type uri' do

    let!(:resource) { FactoryGirl.create :device }
    let!(:type_id)  { resource.type_id }
    before          { resource.update_attributes(type: a_uri(FactoryGirl.create :type)) }

    it 'does not apply the type update' do
      resource.reload.type_id.should == type_id
    end
  end
end
