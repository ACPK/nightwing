require "spec_helper"

describe Nightwing::Sidekiq::QueueStats do
  subject { Nightwing::Sidekiq::QueueStats.new(client: Nightwing::DebugClient.new) }

  describe "#call" do
    let(:fake_queue) { Struct.new(:size, :latency).new(0, 0) }

    before do
      allow(Sidekiq::Queue).to receive(:new).and_return fake_queue
    end

    context "when everything just works" do
      it "increments process count" do
        expect(subject.client).to receive(:measure).with("sidekiq.default.size", 0).and_call_original
        expect(subject.client).to receive(:measure).with("sidekiq.default.latency", 0).and_call_original
        expect(subject.client).to receive(:increment).with("sidekiq.default.processed").and_call_original

        subject.call(nil, nil, "default") do
          # beep
        end
      end
    end

    context "when something fails" do
      it "increments process and failure count" do
        expect(subject.client).to receive(:measure).with("sidekiq.default.size", 0).and_call_original
        expect(subject.client).to receive(:measure).with("sidekiq.default.latency", 0).and_call_original
        expect(subject.client).to receive(:increment).with("sidekiq.default.processed").and_call_original
        expect(subject.client).to receive(:increment).with("sidekiq.default.failed").and_call_original

        expect do
          subject.call(nil, nil, "default") do
            fail "beep"
          end
        end.to raise_error RuntimeError
      end
    end
  end
end
