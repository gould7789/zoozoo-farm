require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:role).with_values(admin: 0, staff: 1) }
  end

  describe "アソシエーション" do
    it { is_expected.to have_many(:health_records).with_foreign_key(:created_by_id).dependent(:nullify) }
    it { is_expected.to have_many(:feeding_records).with_foreign_key(:created_by_id).dependent(:nullify) }
    it { is_expected.to have_many(:notices).with_foreign_key(:created_by_id).dependent(:nullify) }
    it { is_expected.to have_many(:sales_records).with_foreign_key(:created_by_id).dependent(:nullify) }
    it { is_expected.to have_many(:expense_records).with_foreign_key(:created_by_id).dependent(:nullify) }
  end

  describe ".active" do
    it "アクティブなユーザーのみ返す" do
      active_user   = create(:user)
      inactive_user = create(:user, :inactive)

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end

  describe "role" do
    it "デフォルトはstaffである" do
      expect(build(:user).role).to eq("staff")
    end

    it "adminロールを持てる" do
      expect(build(:user, :admin)).to be_admin
    end

    it "staffロールを持てる" do
      expect(build(:user)).to be_staff
    end
  end

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
