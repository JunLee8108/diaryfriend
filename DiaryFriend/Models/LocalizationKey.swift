//
//  LocalizationKey.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/21/25.
//

enum LocalizationKey: String {
    // MARK: - App Level
    case app_loading = "app.loading"
    case app_diary_friend = "app.diary_friend"
    
    // MARK: - Session
    case session_expired_title = "session.expired_title"
    case session_expired_message = "session.expired_message"
    
    // MARK: - Settings ✅
    case settings_title = "settings.title"
    case settings_profile = "settings.profile"
    case settings_name = "settings.name"
    case settings_language = "settings.language"
    case settings_help = "settings.help"
    case settings_about = "settings.about"
    case settings_version = "settings.version"
    case settings_developer = "settings.developer"
    case settings_delete_account = "settings.delete_account"
    
    // MARK: - Language Selection ✅
    case language_select_title = "language.select_title"
    case language_english_desc = "language.english_description"
    case language_korean_desc = "language.korean_description"
    case language_updating = "language.updating"
    
    // MARK: - Edit Name ✅
    case edit_name_title = "edit_name.title"
    case edit_name_display_name = "edit_name.display_name"
    case edit_name_placeholder = "edit_name.placeholder"
    case edit_name_save = "edit_name.save"
    case edit_name_saving = "edit_name.saving"
    case edit_name_too_long = "edit_name.too_long"
    case edit_name_cannot_empty = "edit_name.cannot_empty"
    case edit_name_character_count = "edit_name.character_count"
    case edit_name_update_failed = "edit_name.update_failed"
    
    // MARK: - Delete Account Modal ✅
    case delete_modal_title = "delete_modal.title"
    case delete_modal_warning = "delete_modal.warning"
    case delete_modal_instruction = "delete_modal.instruction"
    case delete_modal_required_text = "delete_modal.required_text"
    case delete_modal_placeholder = "delete_modal.placeholder"
    case delete_modal_cancel = "delete_modal.cancel"
    case delete_modal_delete = "delete_modal.delete"
    
    // MARK: - Help View ✅
    case help_close = "help.close"
    case help_previous = "help.previous"
    case help_next = "help.next"
    case help_done = "help.done"
    
    // Help Slide 1 - Follow
    case help_slide1_title = "help.slide1.title"
    case help_slide1_description = "help.slide1.description"
    
    // Help Slide 2 - Choose
    case help_slide2_title = "help.slide2.title"
    case help_slide2_description = "help.slide2.description"
    
    // Help Slide 3 - Generate
    case help_slide3_title = "help.slide3.title"
    case help_slide3_description = "help.slide3.description"
    
    // Help Slide 4 - Review
    case help_slide4_title = "help.slide4.title"
    case help_slide4_description = "help.slide4.description"
    
    // Help Slide 5 - View
    case help_slide5_title = "help.slide5.title"
    case help_slide5_description = "help.slide5.description"
    
    // MARK: - Character Detail Sheet ✅
    case character_personality = "character.personality"
    case character_affinity_level = "character.affinity_level"
    case character_about = "character.about"
    
    // MARK: - Profile View ✅
    case profile_sign_out = "profile.sign_out"
    case profile_sign_out_title = "profile.sign_out_title"
    case profile_sign_out_message = "profile.sign_out_message"
    case profile_sign_out_confirm = "profile.sign_out_confirm"
    case profile_sign_out_failed = "profile.sign_out_failed"
    case profile_sign_out_error = "profile.sign_out_error"
    case profile_ai_characters = "profile.ai_characters"
    case profile_following = "profile.following"
    case profile_no_characters = "profile.no_characters"
    case profile_show_more = "profile.show_more"
    case profile_show_less = "profile.show_less"
    
    // MARK: - Search View ✅
    case search_placeholder = "search.placeholder"
    case search_empty_title = "search.empty_title"
    case search_empty_description = "search.empty_description"
    case search_no_results = "search.no_results"
    case search_try_different = "search.try_different"
    case search_searched_for = "search.searched_for"
    
    // MARK: - Month Names (짧은 형식)
    case month_jan = "month.jan"
    case month_feb = "month.feb"
    case month_mar = "month.mar"
    case month_apr = "month.apr"
    case month_may = "month.may"
    case month_jun = "month.jun"
    case month_jul = "month.jul"
    case month_aug = "month.aug"
    case month_sep = "month.sep"
    case month_oct = "month.oct"
    case month_nov = "month.nov"
    case month_dec = "month.dec"
    
    // MARK: - Month Picker
    case month_picker_select_year = "month_picker.select_year"
    case month_picker_done = "month_picker.done"
    
    // MARK: - Statistics View
    case stats_this_month = "stats.this_month"
    case stats_posts = "stats.posts"
    case stats_writing_frequency = "stats.writing_frequency"
    case stats_manual_or_ai = "stats.manual_or_ai"
    case stats_manual_written = "stats.manual_written"
    case stats_ai_generated = "stats.ai_generated"
    case stats_mood_stats = "stats.mood_stats"
    case stats_no_mood_data = "stats.no_mood_data"
    case stats_entry_tracker = "stats.entry_tracker"
    case stats_no_entry = "stats.no_entry"
    case stats_entry = "stats.entry"
    
    // MARK: - Mood Names
    case mood_happy = "mood.happy"
    case mood_sad = "mood.sad"
    case mood_neutral = "mood.neutral"
    
    // MARK: - Greetings
    case greeting_morning = "greeting.morning"
    case greeting_afternoon = "greeting.afternoon"
    case greeting_evening = "greeting.evening"
    case greeting_night = "greeting.night"
    
    // MARK: - Recent Posts
    case recent_posts_title = "recent_posts.title"
    case recent_no_posts = "recent_posts.no_posts"
    
    // MARK: - Home View Modals
    case home_future_date_title = "home.future_date_title"
    case home_future_date_message = "home.future_date_message"
    case home_no_internet_title = "home.no_internet_title"
    case home_no_internet_message = "home.no_internet_message"
    
    // MARK: - Post Method Choice
    case post_method_choice_title = "post_method.choice_title"
    case post_method_ai_title = "post_method.ai_title"
    case post_method_ai_description = "post_method.ai_description"
    case post_method_manual_title = "post_method.manual_title"
    case post_method_manual_description = "post_method.manual_description"
    
    // MARK: - Diary Text Section
    case diary_section_title = "diary.section_title"
    case diary_placeholder = "diary.placeholder"
    
    // MARK: - Mood Selection
    case mood_selection_title = "mood.selection_title"
    
    // MARK: - Hashtag Section
    case hashtag_section_title = "hashtag.section_title"
    case hashtag_add_tag = "hashtag.add_tag"
    case hashtag_sheet_title = "hashtag.sheet_title"
    case hashtag_placeholder = "hashtag.placeholder"
    
    // MARK: - Image Section
    case image_section_title = "image.section_title"
    case image_processing = "image.processing"
    case image_add_photo = "image.add_photo"
    
    // MARK: - AI Insights
    case ai_insights_title = "ai_insights.title"
    case ai_insights_description = "ai_insights.description"
    case ai_insights_no_character_message = "ai_insights.no_character_message"
    case ai_insights_find_characters = "ai_insights.find_characters"
    
    // MARK: - Post Save Button
    case post_saving = "post.saving"
    case post_complete_entry = "post.complete_entry"
    case post_save_entry = "post.save_entry"
    case post_accessibility_save_label = "post.accessibility_save_label"
    case post_accessibility_complete_label = "post.accessibility_complete_label"
    case post_accessibility_save_hint = "post.accessibility_save_hint"
    case post_accessibility_complete_hint = "post.accessibility_complete_hint"
    
    // MARK: - LoginView
    case login_subtitle = "login.subtitle"
    case login_apple = "login.apple"
    case login_google = "login.google"
    case login_why_signin = "login.why_signin"
    
    // MARK: - PostAISelectView
    case ai_select_header = "ai_select.header"
    case ai_select_title = "ai_select.title"
    case ai_select_last_chance = "ai_select.last_chance"
    case ai_select_chatted = "ai_select.chatted"
    case ai_select_no_friends = "ai_select.no_friends"
    case ai_select_follow_friends = "ai_select.follow_friends"
    case ai_select_find_friends = "ai_select.find_friends"
    
    // MARK: - PostDetailView
    case post_detail_processing = "post_detail.processing"
    case post_detail_wait = "post_detail.wait"
    case post_detail_empty = "post_detail.empty"
    case post_detail_delete_title = "post_detail.delete_title"
    case post_detail_delete_message = "post_detail.delete_message"
    
    // MARK: - PostAIConversationView
    case ai_conversation_header = "ai_conversation.header"
    case ai_conversation_generate = "ai_conversation.generate"
    case ai_conversation_plenty_shared = "ai_conversation.plenty_shared"
    case ai_conversation_processing = "ai_conversation.processing"
    case ai_conversation_view_diary = "ai_conversation.view_diary"
    case ai_conversation_ready_save = "ai_conversation.ready_save"
    case ai_conversation_messages_remaining = "ai_conversation.messages_remaining"
    case ai_conversation_limit_reached = "ai_conversation.limit_reached"
    
    // MARK: - Personality Types
    case personality_wise = "personality.wise"
    case personality_strategic = "personality.strategic"
    case personality_composed = "personality.composed"
    case personality_witty = "personality.witty"
    case personality_resourceful = "personality.resourceful"
    case personality_adventurous = "personality.adventurous"
    case personality_rebellious = "personality.rebellious"
    case personality_lively = "personality.lively"
    case personality_confident = "personality.confident"
    case personality_clever = "personality.clever"
    case personality_playful = "personality.playful"
    case personality_unpredictable = "personality.unpredictable"
    case personality_loyal = "personality.loyal"
    case personality_disciplined = "personality.disciplined"
    case personality_honorable = "personality.honorable"
    case personality_calm = "personality.calm"
    case personality_spiritual = "personality.spiritual"
    case personality_protective = "personality.protective"
    case personality_radiant = "personality.radiant"
    case personality_nurturing = "personality.nurturing"
    case personality_optimistic = "personality.optimistic"
    case personality_alluring = "personality.alluring"
    case personality_warm = "personality.warm"
    case personality_intuitive = "personality.intuitive"
    case personality_cunning = "personality.cunning"
    case personality_mysterious = "personality.mysterious"
    case personality_graceful = "personality.graceful"
    case personality_creative = "personality.creative"
    case personality_magnetic = "personality.magnetic"
    
    // MARK: - Errors
    case error_title = "error.title"
    case error_network_required = "error.network_required"
    case error_not_authenticated = "error.not_authenticated"
    case error_generic = "error.generic"
    
    // MARK: - Common
    case common_ok = "common.ok"
    case common_cancel = "common.cancel"
    case common_save = "common.save"
    case common_loading = "common.loading"
    case common_done = "common.done"
    case common_add = "common.add"
    case common_edit = "common.edit"
    case common_delete = "common.delete"
    
    // MARK: - Fallback (번역 누락 시)
    var fallback: String {
        switch self {
            // App Level
        case .app_loading:
            return "Loading..."
        case .app_diary_friend:
            return "DiaryFriend"
            
            // Session
        case .session_expired_title:
            return "Session Expired"
        case .session_expired_message:
            return "Your session has expired. Please sign in again."
            
            // Settings
        case .settings_title:
            return "Settings"
        case .settings_profile:
            return "Profile"
        case .settings_name:
            return "Name"
        case .settings_language:
            return "Language"
        case .settings_help:
            return "Help"
        case .settings_about:
            return "About"
        case .settings_version:
            return "Version"
        case .settings_developer:
            return "Developer"
        case .settings_delete_account:
            return "Delete Account"
            
            // Language Selection
        case .language_select_title:
            return "Select Language"
        case .language_english_desc:
            return "Use English for all app content"
        case .language_korean_desc:
            return "Use Korean for all app content"
        case .language_updating:
            return "Updating..."
            
            // Edit Name
        case .edit_name_title:
            return "Edit Name"
        case .edit_name_display_name:
            return "Display Name"
        case .edit_name_placeholder:
            return "Enter your name"
        case .edit_name_save:
            return "Save"
        case .edit_name_saving:
            return "Saving..."
        case .edit_name_too_long:
            return "Name is too long"
        case .edit_name_cannot_empty:
            return "Name cannot be empty"
        case .edit_name_character_count:
            return "%d/30"
        case .edit_name_update_failed:
            return "Failed to update name"
            
            // Delete Account Modal
        case .delete_modal_title:
            return "Delete Account?"
        case .delete_modal_warning:
            return "This action cannot be undone."
        case .delete_modal_instruction:
            return "Type \"%@\" to confirm:"
        case .delete_modal_required_text:
            return "DELETE ACCOUNT"
        case .delete_modal_placeholder:
            return ""
        case .delete_modal_cancel:
            return "Cancel"
        case .delete_modal_delete:
            return "Delete"
            
            // Help View
        case .help_close:
            return "Close"
        case .help_previous:
            return "Previous"
        case .help_next:
            return "Next"
        case .help_done:
            return "Done"
            
            // Help Slide 1
        case .help_slide1_title:
            return "Follow AI Characters"
        case .help_slide1_description:
            return "Find and follow AI characters who can chat with you for diary writing and provide insights on your entries."
            
            // Help Slide 2
        case .help_slide2_title:
            return "Choose Your AI Friend"
        case .help_slide2_description:
            return "Select an AI friend to chat with for your diary writing."
            
            // Help Slide 3
        case .help_slide3_title:
            return "Generate Your Diary"
        case .help_slide3_description:
            return "Once you've had enough conversation, tap the Generate button to create your diary entry."
            
            // Help Slide 4
        case .help_slide4_title:
            return "Review and Edit"
        case .help_slide4_description:
            return "Check the AI-generated diary and customize the content, mood, tags, and photos as you like."
            
            // Help Slide 5
        case .help_slide5_title:
            return "View Your Diary"
        case .help_slide5_description:
            return "Check your completed diary. If AI Insight is enabled, AI friends will have left comments based on your entry!"
            
            // Character Detail Sheet
        case .character_personality:
            return "Personality"
        case .character_affinity_level:
            return "Affinity Level"
        case .character_about:
            return "About"
            
            // Profile View
        case .profile_sign_out:
            return "Sign Out"
        case .profile_sign_out_title:
            return "Sign Out"
        case .profile_sign_out_message:
            return "Are you sure you want to sign out?"
        case .profile_sign_out_confirm:
            return "Sign Out"
        case .profile_sign_out_failed:
            return "Sign Out Failed"
        case .profile_sign_out_error:
            return "Failed to sign out. Please try again."
        case .profile_ai_characters:
            return "AI Characters"
        case .profile_following:
            return "following"
        case .profile_no_characters:
            return "No characters available"
        case .profile_show_more:
            return "Show %d More"
        case .profile_show_less:
            return "Show Less"
            
            // Search View
        case .search_placeholder:
            return "Search posts, dates, moods..."
        case .search_empty_title:
            return "Search your memories"
        case .search_empty_description:
            return "Find posts by content or mood"
        case .search_no_results:
            return "No results found"
        case .search_try_different:
            return "Try different keywords or dates"
        case .search_searched_for:
            return "Searched for: \"%@\""
            
            // Month Names
        case .month_jan: return "Jan"
        case .month_feb: return "Feb"
        case .month_mar: return "Mar"
        case .month_apr: return "Apr"
        case .month_may: return "May"
        case .month_jun: return "Jun"
        case .month_jul: return "Jul"
        case .month_aug: return "Aug"
        case .month_sep: return "Sep"
        case .month_oct: return "Oct"
        case .month_nov: return "Nov"
        case .month_dec: return "Dec"
            
            // Month Picker
        case .month_picker_select_year: return "Select Year"
        case .month_picker_done: return "Done"
            
            // Statistics View
        case .stats_this_month:
            return "THIS MONTH"
        case .stats_posts:
            return "Posts"
        case .stats_writing_frequency:
            return "Writing Frequency"
        case .stats_manual_or_ai:
            return "MANUAL or AI"
        case .stats_manual_written:
            return "Manual Written"
        case .stats_ai_generated:
            return "AI Generated"
        case .stats_mood_stats:
            return "MOOD STATS"
        case .stats_no_mood_data:
            return "No mood data available"
        case .stats_entry_tracker:
            return "ENTRY TRACKER"
        case .stats_no_entry:
            return "No entry"
        case .stats_entry:
            return "Entry"
            
            // Mood Names
        case .mood_happy:
            return "Happy"
        case .mood_sad:
            return "Sad"
        case .mood_neutral:
            return "Neutral"
            
            // Greetings
        case .greeting_morning:
            return "Good morning"
        case .greeting_afternoon:
            return "Good afternoon"
        case .greeting_evening:
            return "Good evening"
        case .greeting_night:
            return "Good night"
            
            // Recent Posts
        case .recent_posts_title:
            return "RECENT"
        case .recent_no_posts:
            return "No posts in %@"
            
            // Home View Modals
        case .home_future_date_title:
            return "Future Date"
        case .home_future_date_message:
            return "You cannot create entries for future dates."
        case .home_no_internet_title:
            return "No Internet"
        case .home_no_internet_message:
            return "Please check your internet connection."
            
            // Post Method Choice
        case .post_method_choice_title:
            return "How would you like to write today?"
        case .post_method_ai_title:
            return "Chat with AI"
        case .post_method_ai_description:
            return "Let AI help you express your thoughts"
        case .post_method_manual_title:
            return "Write Freely"
        case .post_method_manual_description:
            return "Express yourself in your own words"
            
            // Diary Text Section
        case .diary_section_title:
            return "Today's story"
        case .diary_placeholder:
            return "Share your thoughts, feelings, or anything that happened today..."
            
            // Mood Selection
        case .mood_selection_title:
            return "How are you feeling?"
            
            // Hashtag Section
        case .hashtag_section_title:
            return "Tag"
        case .hashtag_add_tag:
            return "Add tag"
        case .hashtag_sheet_title:
            return "Add a tag"
        case .hashtag_placeholder:
            return "Enter tag"
            
            // Image Section
        case .image_section_title:
            return "Photo"
        case .image_processing:
            return "Processing..."
        case .image_add_photo:
            return "Add photo"
            
            // AI Insights
        case .ai_insights_title:
            return "AI Insights"
        case .ai_insights_description:
            return "Get thoughtful AI feedback on your entry"
        case .ai_insights_no_character_message:
            return "Follow a character to enable AI insights"
        case .ai_insights_find_characters:
            return "Find Characters"
            
            // Post Save Button
        case .post_saving:
            return "Saving..."
        case .post_complete_entry:
            return "Complete your entry"
        case .post_save_entry:
            return "Save Entry"
        case .post_accessibility_save_label:
            return "Save your diary entry"
        case .post_accessibility_complete_label:
            return "Complete your entry to save"
        case .post_accessibility_save_hint:
            return "Tap to save your diary entry"
        case .post_accessibility_complete_hint:
            return "Fill in at least 10 characters to enable saving"
            
            // loginView
        case .login_subtitle:
            return "Sign in to start diary journy with AI friends!"
        case .login_apple:
            return "Continue with Apple"
        case .login_google:
            return "Continue with Google"
        case .login_why_signin:
            return "Why sign in?"
            
            // PostAISelectView
        case .ai_select_header:
            return "AI Chat"
        case .ai_select_title:
            return "Who would you like to chat with?"
        case .ai_select_last_chance:
            return "Last rewrite chance for this date (1/2)"
        case .ai_select_chatted:
            return "Chatted"
        case .ai_select_no_friends:
            return "No AI Friends Yet"
        case .ai_select_follow_friends:
            return "Follow AI Characters to start chatting"
        case .ai_select_find_friends:
            return "Find Characters"
            
            // PostDetailView
        case .post_detail_processing:
            return "Your AI friends are writing comments..."
        case .post_detail_wait:
            return "Please wait a moment"
        case .post_detail_empty:
            return "No AI Insights yet"
        case .post_detail_delete_title:
            return "Delete Post"
        case .post_detail_delete_message:
            return "Are you sure you want to delete this post? This action cannot be undone."
            
            // PostAIConversationView
        case .ai_conversation_header:
            return "Chat with AI"
        case .ai_conversation_generate:
            return "Generate your diary!"
        case .ai_conversation_plenty_shared:
            return "Plenty has been shared."
        case .ai_conversation_processing:
            return "Generating your diary..."
        case .ai_conversation_view_diary:
            return "View your diary"
        case .ai_conversation_ready_save:
            return "Generated and ready to save"
        case .ai_conversation_messages_remaining:
            return "%d messages remaining"
        case .ai_conversation_limit_reached:
            return "Conversation limit reached (10 messages)"
            
            // Personality Types
        case .personality_wise: return "Wise"
        case .personality_strategic: return "Strategic"
        case .personality_composed: return "Composed"
        case .personality_witty: return "Witty"
        case .personality_resourceful: return "Resourceful"
        case .personality_adventurous: return "Adventurous"
        case .personality_rebellious: return "Rebellious"
        case .personality_lively: return "Lively"
        case .personality_confident: return "Confident"
        case .personality_clever: return "Clever"
        case .personality_playful: return "Playful"
        case .personality_unpredictable: return "Unpredictable"
        case .personality_loyal: return "Loyal"
        case .personality_disciplined: return "Disciplined"
        case .personality_honorable: return "Honorable"
        case .personality_calm: return "Calm"
        case .personality_spiritual: return "Spiritual"
        case .personality_protective: return "Protective"
        case .personality_radiant: return "Radiant"
        case .personality_nurturing: return "Nurturing"
        case .personality_optimistic: return "Optimistic"
        case .personality_alluring: return "Alluring"
        case .personality_warm: return "Warm"
        case .personality_intuitive: return "Intuitive"
        case .personality_cunning: return "Cunning"
        case .personality_mysterious: return "Mysterious"
        case .personality_graceful: return "Graceful"
        case .personality_creative: return "Creative"
        case .personality_magnetic: return "Magnetic"
            
            // Errors
        case .error_title:
            return "Error"
        case .error_network_required:
            return "Internet connection is required to delete your account."
        case .error_not_authenticated:
            return "Authentication error. Please sign in again."
        case .error_generic:
            return "An error occurred"
            
            // Common
        case .common_ok:
            return "OK"
        case .common_cancel:
            return "Cancel"
        case .common_save:
            return "Save"
        case .common_loading:
            return "Loading..."
        case .common_done:
            return "Done"
        case .common_add:
            return "Add"
        case .common_edit:
            return "Edit"
        case .common_delete:
            return "Delete"
        }
    }
}
