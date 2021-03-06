class User < ActiveRecord::Base
    before_save { self.email = self.email.downcase }
    validates :name, presence: true, length: { maximum: 50 }
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/
    validates :email, presence: true, length: { maximum: 255 },
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
    has_secure_password
    
    has_many :recipes
    
    has_many :following_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
    has_many :following_users, through: :following_relationships, source: :followed
    
    has_many :follower_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
    has_many :follower_users, through: :follower_relationships, source: :follower
    
    has_many :likes
    has_many :like_recipes, through: :likes, source: :recipe
    
    mount_uploader :image, ImageUploader
    
    # 他のユーザーをフォローする
    def follow(other_user)
        following_relationships.find_or_create_by(followed_id: other_user.id)
    end

    # フォローしているユーザーをアンフォローする
    def unfollow(other_user)
        following_relationship = following_relationships.find_by(followed_id: other_user.id)
        following_relationship.destroy if following_relationship
    end

    # あるユーザーをフォローしているかどうか？
    def following?(other_user)
        following_users.include?(other_user)
    end
    
    def feed_items
        Recipe.where(user_id: following_user_ids + [self.id])
    end

    def like?(recipe)
        like_recipes.include?(recipe)
    end
    
    def like!(recipe)
        likes.find_or_create_by(recipe_id: recipe.id)
    end
    
    def unlike!(recipe)
        likes.find_by(recipe_id: recipe.id).destroy
    end

end
