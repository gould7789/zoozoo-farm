# DB 제약이 범위 밖 enum 값을 거부하는지 확인한다.
#
# update_column 을 쓰는 이유는 update 가 모델 검증에 먼저 걸려
# DB 까지 가지 않기 때문이다. 모델을 우회해야 DB 를 검증한 것이 된다.
# update_all · insert_all · 생SQL · 백필이 실제로 지나는 경로가 이쪽이다.
RSpec.shared_examples "DB 가 범위 밖 enum 값을 거부한다" do |column, bad_value|
  it "#{column} 에 #{bad_value} 를 직접 넣으면 DB 가 거부한다" do
    record = create(described_class.model_name.param_key.to_sym)

    expect {
      record.update_column(column, bad_value)
    }.to raise_error(ActiveRecord::StatementInvalid, /chk_/)
  end
end
