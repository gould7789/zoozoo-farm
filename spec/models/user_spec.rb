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

  # 記録を持つユーザーは物理削除を禁止する — 監査証跡（作成者情報）を保持するため
  describe "アソシエーション" do
    it { is_expected.to have_many(:health_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:feeding_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:notices).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:sales_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:expense_records).with_foreign_key(:created_by_id).dependent(:restrict_with_error) }
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

  # フォームのプレースホルダー「8자 이상」とko.ymlのtoo_shortメッセージに
  # モデル側の検証を一致させる
  describe "パスワードの長さ" do
    it "8文字未満は無効" do
      user = build(:user, password: "pass123")
      expect(user).to be_invalid
      expect(user.errors[:password]).to include("비밀번호는 8자 이상이어야 합니다.")
    end

    it "8文字以上は有効" do
      expect(build(:user, password: "pass1234")).to be_valid
    end

    # 編集画面でパスワード欄を空にした場合、コントローラーが:passwordをparamsから
    # 除外するためpasswordはnilになる — そのケースで長さ検証に引っかからないこと
    it "更新時にパスワードが空なら長さ検証をスキップする" do
      user_id = create(:user, password: "password123").id
      user    = User.find(user_id)

      expect(user.password).to be_nil
      expect(user.update(name: "山田太郎")).to be true
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
