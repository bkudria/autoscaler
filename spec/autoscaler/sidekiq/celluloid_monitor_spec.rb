require 'spec_helper'
require 'autoscaler/sidekiq/celluloid_monitor'
require 'timeout'

describe Autoscaler::Sidekiq::CelluloidMonitor do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::CelluloidMonitor}
  let(:scaler) {TestScaler.new(1)}
  let(:system) {
    stub('system').tap do |s|
      s.stub(:queue_names).and_return(['queues'])
    end
  }
  let(:manager) {cut.new(scaler, 0, system)}

  it "scales with no work" do
    system.stub(:pending_work?).and_return(false)
    Timeout.timeout(1) { manager.wait_for_downscale }
    scaler.workers.should == 0
    manager.terminate
  end

  it "does not scale with pending work" do
    system.stub(:pending_work?).and_return(true)
    expect {Timeout.timeout(1) { manager.wait_for_downscale }}.to raise_error Timeout::Error
    scaler.workers.should == 1
    manager.terminate
  end
end