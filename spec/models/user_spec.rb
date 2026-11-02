require "rails_helper"

RSpec.describe User, type: :model do
  describe "검증" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:role).with_values(admin: 0, staff: 1) }
  end

  # 기록을 가진 사용자는 물리 삭제를 막는다 — 감사 추적(작성자)을 보존해야 한다
  describe "연관" do
    it { is_expected.to have_many(:health_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:feeding_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:notices).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:sales_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:expense_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
  end

  describe ".active" do
    it "active 사용자만 반환한다" do
      active_user   = create(:user)
      inactive_user = create(:user, :inactive)

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end

  describe "role" do
    it "기본값은 staff 다" do
      expect(build(:user).role).to eq("staff")
    end

    it "admin 역할을 가질 수 있다" do
      expect(build(:user, :admin)).to be_admin
    end

    it "staff 역할을 가질 수 있다" do
      expect(build(:user)).to be_staff
    end
  end

  # 폼의 placeholder 「8자 이상」과 ko.yml 의 too_short 메시지에 모델 검증을 맞춘다
  describe "비밀번호 길이" do
    it "8자 미만은 무효" do
      user = build(:user, password: "pass123")
      expect(user).to be_invalid
      expect(user.errors[:password]).to include("비밀번호는 8자 이상이어야 합니다.")
    end

    it "8자 이상은 유효" do
      expect(build(:user, password: "pass1234")).to be_valid
    end

    # 수정 화면에서 비밀번호 칸을 비우면 컨트롤러가 :password 를 params 에서 빼
    # password 가 nil 이 된다 — 그 경우 길이 검증에 걸리지 않아야 한다
    it "수정 시 비밀번호가 비어 있으면 길이 검증을 건너뛴다" do
      user_id = create(:user, password: "password123").id
      user    = User.find(user_id)

      expect(user.password).to be_nil
      expect(user.update(name: "홍길동")).to be true
    end
  end

  describe "password authentication" do
    it "올바른 비밀번호로 인증된다" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "틀린 비밀번호로는 인증되지 않는다" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("wrongpassword")).to be false
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :role, 9, "chk_users_role"
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :position, 9, "chk_users_position"

    # 팩토리는 position 을 넣지 않으므로, 값이 있는 상태에서 NULL 로 바꿔야
    # 전이를 확인한 것이 된다. CHECK 는 식이 FALSE 일 때만 거부하고
    # NULL IN (...) 은 NULL 로 평가되므로 통과한다
    it "position 은 값이 있다가 NULL 이 되는 것도 받는다 — Staff 는 직급이 없다" do
      user = create(:user, position: :manager)

      expect { user.update_column(:position, nil) }.not_to raise_error
      expect(user.reload.position).to be_nil
    end
  end
end
