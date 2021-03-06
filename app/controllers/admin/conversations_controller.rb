class Admin::ConversationsController < Admin::AdminApplicationController
  include AccessMethods
  
  skip_before_action :require_admin_privileges, only: [:blacklist_voter_phone, :unblacklist_voter_phone, :close] 
  before_action :set_conversation, only: [:show, :messages, :ride_pane, :update_attribute, :close, :blacklist_voter_phone, :unblacklist_voter_phone]

  # GET /admin/conversations
  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 25
    @conversations = Conversation.all.paginate(page: page, per_page: per_page).order("created_at ASC")
  end

  # GET /admin/conversations/1
  def show
  end


  ## REQUIRE dispatch permissions on the ride zone the conversation is attached to before
  ## permitting use of close and blacklisting
  
  # POST /admin/conversations/1/close
  
  # user_signed_in?
  def close
    @ride_zone = @conversation.ride_zone
    
    if user_signed_in? && has_zone_dispatch?
      @conversation.close(current_user.name)
      flash[:notice] = "Conversation closed."
      redirect_back(fallback_location: root_path) and return
    else
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end

  # POST /admin/converations/1/blacklist_voter_phone
  def blacklist_voter_phone
    if user_signed_in? && has_zone_dispatch?
      @conversation.blacklist_voter_phone
      flash[:notice] = "Voter Phone Blacklisted."
      redirect_back(fallback_location: root_path) and return
    else
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end

  # POST /admin/converations/1/unblacklist_voter_phone
  def unblacklist_voter_phone
    if user_signed_in? && has_zone_dispatch?
      @conversation.unblacklist_voter_phone
      flash[:notice] = "Voter Phone No Longer Blacklisted."
      redirect_back(fallback_location: root_path) and return
    else
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end

  private
  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
