require 'spec_helper'

describe Universign::Transaction do
  let(:document) do
    Universign::Document.new(
      name:    'original_contract.pdf',
      content: File.open('spec/fixtures/universign-guide-8.8.pdf').read
    )
  end

  describe ".create" do
    subject do
      VCR.use_cassette(cassette) do
        Universign::Transaction.create(
          documents: [document],
          signers:   [signer],
          options: options
        )
      end
    end

    let(:options) { { profile: 'default', final_doc_sent: true } }

    let(:signer) do
      Universign::TransactionSigner.new(
        first_name:   "Signer's first name",
        last_name:    "Signer's last name",
        email: 'test@gmail.com',
        # phone_number: "0132456789",
        success_url:  "http://success-url.com/",
        signature:    signature
      )
    end

    context 'with a named signature field' do
      let(:cassette) { 'transaction/create_with_named_field' }
      let(:signature) { Universign::SignatureField.new(coordinate: [20, 20], name: 'test', page: 1) }

      it 'Gets a valid url' do
        expect(subject.url).to match(/https:\/\/.*universign\.eu/)
      end
    end

    context 'with a named signature and a chaining mode fields' do
      let(:cassette) { 'transaction/create_with_chaining_mode_field' }
      let(:options) do
        { profile: 'default', final_doc_sent: true, chaining_mode: 'none' }
      end
      let(:signature) do
        Universign::SignatureField.new(coordinate: [20, 20], name: 'test', page: 1)
      end

      it 'Gets a valid url' do
        expect(subject.url).to match(/https:\/\/.*universign\.eu/)
      end
    end

    context 'with a coordinate signature field' do
      let(:cassette) { 'transaction/create_with_coordinate_field' }
      let(:signature) { Universign::SignatureField.new(coordinate: [20, 20], page: 1) }

      it 'Gets a valid url' do
        expect(subject.url).to match(/https:\/\/.*universign\.eu/)
      end
    end
  end

  describe "#signed?" do
    it 'is signed with status == completed' do
      transaction = VCR.use_cassette('transaction/signed/signed') do
        Universign::Transaction.new('0ece5074-2273-491e-9315-9b1d1f0bbba8')
      end

      expect(transaction.signed?).to be true
    end

    it 'is not signed otherwise' do
      transaction = VCR.use_cassette('transaction/signed/not_signed') do
        Universign::Transaction.new('5512fd62-8bdc-45a1-9a37-661baeb0bdb0')
      end

      expect(transaction.signed?).to be false
    end
  end
end
