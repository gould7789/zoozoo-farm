require "rails_helper"

RSpec.describe User, type: :model do
  # バリデーションのテスト
  describe "validations" do
    subject { build(:user) }

    # メールアドレス
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    # 名前
    it { is_expected.to validate_presence_of(:name) }

    # パスワード（has_secure_passwordが自動追加）
    it { is_expected.to validate_presence_of(:password) }
  end

  # enumのテスト
  describe "enum" do
    it { is_expected.to define_enum_for(:role).with_values(admin: 0, staff: 1) }
  end

  # アソシエーションのテスト（Phase3以降で追加予定）
  # it { is_expected.to have_many(:health_records) }
  # it { is_expected.to have_many(:feeding_records) }

  # スコープのテスト
  describe ".active" do
    it "アクティブなユーザーのみ返す" do
      active_user   = create(:user)
      inactive_user = create(:user, :inactive)

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end

  # ロールのテスト
  describe "role" do
    it "デフォルトはstaffである" do
      user = build(:user)
      expect(user.role).to eq("staff")
    end

    it "adminロールを持てる" do
      admin = build(:user, :admin)
      expect(admin.admin?).to be true
    end

    it "staffロールを持てる" do
      staff = build(:user)
      expect(staff.staff?).to be true
    end
  end

  # has_secure_passwordのテスト
  describe "password authentication" do
    it "正しいパスワードで認証できる" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "間違ったパスワードでは認証できない" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("wrongpassword")).to be false
    end
  end
end
