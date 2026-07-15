# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_15_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcement_reads", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["announcement_id", "user_id"], name: "index_announcement_reads_on_announcement_id_and_user_id", unique: true
    t.index ["announcement_id"], name: "index_announcement_reads_on_announcement_id"
    t.index ["read_at"], name: "index_announcement_reads_on_read_at"
    t.index ["user_id"], name: "index_announcement_reads_on_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.boolean "pinned", default: false, null: false
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["category"], name: "index_announcements_on_category"
    t.index ["expires_at"], name: "index_announcements_on_expires_at"
    t.index ["pinned"], name: "index_announcements_on_pinned"
    t.index ["published_at"], name: "index_announcements_on_published_at"
    t.index ["status", "pinned", "published_at"], name: "idx_announcements_on_status_pinned_published"
    t.index ["status"], name: "index_announcements_on_status"
  end

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_app_settings_on_key", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.datetime "checked_in_at", null: false
    t.bigint "checked_in_by_id"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["checked_in_at"], name: "index_attendances_on_checked_in_at"
    t.index ["checked_in_by_id"], name: "index_attendances_on_checked_in_by_id"
    t.index ["event_id", "user_id"], name: "index_attendances_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id"
    t.index ["action", "created_at"], name: "index_audit_logs_on_action_and_created_at"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id", "created_at"], name: "idx_audit_logs_on_auditable_and_created_at"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "document_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_document_categories_on_active_and_position"
    t.index ["active"], name: "index_document_categories_on_active"
    t.index ["name"], name: "index_document_categories_on_name", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "document_category_id", null: false
    t.datetime "expires_at"
    t.jsonb "letter_data", default: {}, null: false
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.integer "visibility", default: 1, null: false
    t.index ["document_category_id", "status"], name: "index_documents_on_document_category_id_and_status"
    t.index ["document_category_id"], name: "index_documents_on_document_category_id"
    t.index ["expires_at"], name: "index_documents_on_expires_at"
    t.index ["published_at"], name: "index_documents_on_published_at"
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
    t.index ["visibility", "status", "published_at"], name: "index_documents_on_visibility_and_status_and_published_at"
    t.index ["visibility"], name: "index_documents_on_visibility"
  end

  create_table "event_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_event_categories_on_active"
    t.index ["name"], name: "index_event_categories_on_name", unique: true
    t.index ["position"], name: "index_event_categories_on_position"
  end

  create_table "event_registrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.text "note"
    t.datetime "registered_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id", "status"], name: "index_event_registrations_on_event_id_and_status"
    t.index ["event_id", "user_id"], name: "index_event_registrations_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_registrations_on_event_id"
    t.index ["registered_at"], name: "index_event_registrations_on_registered_at"
    t.index ["user_id"], name: "index_event_registrations_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "capacity"
    t.string "city"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.datetime "end_time", null: false
    t.bigint "event_category_id", null: false
    t.date "event_date", null: false
    t.string "location"
    t.integer "max_participants"
    t.string "prefecture"
    t.datetime "published_at"
    t.datetime "registration_deadline"
    t.boolean "registration_required", default: false, null: false
    t.datetime "start_time", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "venue"
    t.integer "visibility", default: 1, null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["event_category_id"], name: "index_events_on_event_category_id"
    t.index ["event_date"], name: "index_events_on_event_date"
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["status", "start_time"], name: "index_events_on_status_and_start_time"
    t.index ["status"], name: "index_events_on_status"
    t.index ["visibility", "status", "start_time"], name: "index_events_on_visibility_and_status_and_start_time"
    t.index ["visibility"], name: "index_events_on_visibility"
  end

  create_table "family_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.bigint "member_profile_id", null: false
    t.string "membership_number"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "relationship", null: false
    t.datetime "updated_at", null: false
    t.index ["member_profile_id"], name: "index_family_members_on_member_profile_id"
    t.index ["member_profile_id"], name: "index_family_members_on_unique_spouse", unique: true, where: "(lower((relationship)::text) = 'spouse'::text)"
    t.index ["membership_number"], name: "index_family_members_on_membership_number", unique: true, where: "(membership_number IS NOT NULL)"
  end

  create_table "finance_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "category_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category_type", "active"], name: "index_finance_categories_on_category_type_and_active"
    t.index ["name", "category_type"], name: "index_finance_categories_on_name_and_category_type", unique: true
  end

  create_table "finance_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "finance_category_id", null: false
    t.bigint "recorded_by_id", null: false
    t.string "reference_number"
    t.integer "status", default: 0, null: false
    t.date "transaction_date", null: false
    t.integer "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_finance_transactions_on_approved_by_id"
    t.index ["finance_category_id"], name: "index_finance_transactions_on_finance_category_id"
    t.index ["recorded_by_id"], name: "index_finance_transactions_on_recorded_by_id"
    t.index ["reference_number"], name: "index_finance_transactions_on_reference_number"
    t.index ["transaction_date"], name: "index_finance_transactions_on_transaction_date"
    t.index ["transaction_type", "status", "transaction_date"], name: "idx_finance_transactions_on_type_status_date"
  end

  create_table "meeting_minute_attendances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "meeting_minute_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["meeting_minute_id", "status"], name: "idx_on_meeting_minute_id_status_b83db3238d"
    t.index ["meeting_minute_id", "user_id"], name: "index_meeting_minute_attendances_on_minute_and_user", unique: true
    t.index ["meeting_minute_id"], name: "index_meeting_minute_attendances_on_meeting_minute_id"
    t.index ["user_id"], name: "index_meeting_minute_attendances_on_user_id"
  end

  create_table "meeting_minutes", force: :cascade do |t|
    t.integer "absent_count", default: 0, null: false
    t.text "adjournment"
    t.integer "apologies_count", default: 0, null: false
    t.datetime "approved_at"
    t.text "attendance_notes"
    t.string "chairman"
    t.string "chairman_signature_name"
    t.string "chairman_signature_title"
    t.datetime "created_at", null: false
    t.text "decisions"
    t.integer "guests_count", default: 0, null: false
    t.date "meeting_date", null: false
    t.time "meeting_time"
    t.string "minute_recorder"
    t.string "opening_prayer"
    t.integer "present_count", default: 0, null: false
    t.text "previous_minutes_approval"
    t.datetime "published_at"
    t.text "reports"
    t.string "secretary_signature_name"
    t.string "secretary_signature_title"
    t.integer "status", default: 0, null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.string "venue"
    t.string "welcome_speech"
    t.index ["meeting_date"], name: "index_meeting_minutes_on_meeting_date"
    t.index ["published_at"], name: "index_meeting_minutes_on_published_at"
    t.index ["status", "meeting_date"], name: "index_meeting_minutes_on_status_and_meeting_date"
    t.index ["status"], name: "index_meeting_minutes_on_status"
    t.index ["uploaded_by_id"], name: "index_meeting_minutes_on_uploaded_by_id"
  end

  create_table "member_profiles", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.integer "family_status", default: 0, null: false
    t.string "father_name"
    t.string "full_name", null: false
    t.integer "gender"
    t.date "joined_on"
    t.string "membership_number", null: false
    t.string "mobile_number"
    t.string "mother_name"
    t.text "notes"
    t.string "postal_code"
    t.string "prefecture"
    t.string "spouse_name"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["city"], name: "index_member_profiles_on_city"
    t.index ["family_status"], name: "index_member_profiles_on_family_status"
    t.index ["full_name"], name: "index_member_profiles_on_full_name"
    t.index ["membership_number"], name: "index_member_profiles_on_membership_number", unique: true
    t.index ["mobile_number"], name: "index_member_profiles_on_mobile_number", unique: true, where: "((mobile_number IS NOT NULL) AND ((mobile_number)::text <> ''::text))"
    t.index ["prefecture"], name: "index_member_profiles_on_prefecture"
    t.index ["status", "created_at"], name: "index_member_profiles_on_status_and_created_at"
    t.index ["user_id"], name: "index_member_profiles_on_user_id", unique: true
  end

  create_table "membership_payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "approved_by_id"
    t.string "beneficiary_membership_number"
    t.string "beneficiary_name"
    t.datetime "created_at", null: false
    t.bigint "family_member_id"
    t.bigint "membership_plan_id", null: false
    t.text "notes"
    t.datetime "paid_on"
    t.bigint "payment_batch_id"
    t.integer "payment_method", default: 1, null: false
    t.integer "payment_month"
    t.integer "payment_year", null: false
    t.datetime "receipt_shared_at"
    t.bigint "receipt_shared_by_id"
    t.string "reference_number"
    t.integer "status", default: 0, null: false
    t.decimal "transfer_amount", precision: 10, scale: 2
    t.string "transfer_reference_name"
    t.date "transferred_on"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "family_member_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)", name: "idx_unique_family_member_payment_period", unique: true, where: "((family_member_id IS NOT NULL) AND (status = ANY (ARRAY[0, 3, 4, 5, 8])))"
    t.index "user_id, membership_plan_id, payment_year, COALESCE(payment_month, 0)", name: "idx_unique_guardian_payment_period", unique: true, where: "((family_member_id IS NULL) AND (status = ANY (ARRAY[0, 3, 4, 5, 8])))"
    t.index ["approved_by_id"], name: "index_membership_payments_on_approved_by_id"
    t.index ["family_member_id"], name: "index_membership_payments_on_family_member_id"
    t.index ["membership_plan_id"], name: "index_membership_payments_on_membership_plan_id"
    t.index ["payment_batch_id"], name: "index_membership_payments_on_payment_batch_id"
    t.index ["payment_year"], name: "index_membership_payments_on_payment_year"
    t.index ["receipt_shared_by_id"], name: "index_membership_payments_on_receipt_shared_by_id"
    t.index ["reference_number"], name: "index_membership_payments_on_reference_number"
    t.index ["status", "created_at"], name: "index_membership_payments_on_status_and_created_at"
    t.index ["transfer_reference_name"], name: "index_membership_payments_on_transfer_reference_name"
    t.index ["transferred_on"], name: "index_membership_payments_on_transferred_on"
    t.index ["user_id", "created_at"], name: "index_membership_payments_on_user_id_and_created_at"
    t.index ["user_id", "payment_year", "payment_month"], name: "idx_membership_payments_on_user_and_period"
    t.index ["user_id"], name: "index_membership_payments_on_user_id"
  end

  create_table "membership_plan_types", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_membership_plan_types_on_active"
    t.index ["code"], name: "index_membership_plan_types_on_code", unique: true
    t.index ["name"], name: "index_membership_plan_types_on_name", unique: true
  end

  create_table "membership_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "billing_cycle", default: 1, null: false
    t.decimal "child_amount", precision: 10, scale: 2
    t.boolean "child_fee_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "membership_plan_type_id", null: false
    t.string "name", null: false
    t.boolean "required_for_members", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "billing_cycle"], name: "index_membership_plans_on_active_and_billing_cycle"
    t.index ["active", "required_for_members"], name: "index_membership_plans_on_active_and_required"
    t.index ["membership_plan_type_id"], name: "index_membership_plans_on_membership_plan_type_id"
    t.index ["name"], name: "index_membership_plans_on_name", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "action", null: false
    t.bigint "actor_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id", "action", "notifiable_type", "notifiable_id"], name: "idx_notifications_unique_recipient_action_notifiable", unique: true
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "payment_batches", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "transfer_amount", precision: 10, scale: 2
    t.string "transfer_reference_name"
    t.date "transferred_on"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved_by_id"], name: "index_payment_batches_on_approved_by_id"
    t.index ["status", "created_at"], name: "index_payment_batches_on_status_and_created_at"
    t.index ["transfer_reference_name"], name: "index_payment_batches_on_transfer_reference_name"
    t.index ["user_id"], name: "index_payment_batches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 7, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "volunteer_signups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "volunteer_slot_id", null: false
    t.index ["user_id"], name: "index_volunteer_signups_on_user_id"
    t.index ["volunteer_slot_id", "status"], name: "index_volunteer_signups_on_volunteer_slot_id_and_status"
    t.index ["volunteer_slot_id", "user_id"], name: "index_volunteer_signups_on_volunteer_slot_id_and_user_id", unique: true
    t.index ["volunteer_slot_id"], name: "index_volunteer_signups_on_volunteer_slot_id"
  end

  create_table "volunteer_slots", force: :cascade do |t|
    t.integer "assigned_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "event_id", null: false
    t.integer "needed_count", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "status"], name: "index_volunteer_slots_on_event_id_and_status"
    t.index ["event_id"], name: "index_volunteer_slots_on_event_id"
  end

  create_table "welfare_attachments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.bigint "welfare_case_id", null: false
    t.index ["uploaded_by_id"], name: "index_welfare_attachments_on_uploaded_by_id"
    t.index ["welfare_case_id"], name: "index_welfare_attachments_on_welfare_case_id"
  end

  create_table "welfare_cases", force: :cascade do |t|
    t.bigint "assigned_to_id"
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "priority", default: 1, null: false
    t.datetime "resolved_at"
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "welfare_category_id", null: false
    t.index ["assigned_to_id"], name: "index_welfare_cases_on_assigned_to_id"
    t.index ["priority"], name: "index_welfare_cases_on_priority"
    t.index ["resolved_at"], name: "index_welfare_cases_on_resolved_at"
    t.index ["status", "priority", "submitted_at"], name: "index_welfare_cases_on_status_and_priority_and_submitted_at"
    t.index ["status"], name: "index_welfare_cases_on_status"
    t.index ["submitted_at"], name: "index_welfare_cases_on_submitted_at"
    t.index ["user_id", "status", "submitted_at"], name: "index_welfare_cases_on_user_status_submitted_at"
    t.index ["user_id"], name: "index_welfare_cases_on_user_id"
    t.index ["welfare_category_id"], name: "index_welfare_cases_on_welfare_category_id"
  end

  create_table "welfare_categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_welfare_categories_on_active"
    t.index ["name"], name: "index_welfare_categories_on_name", unique: true
  end

  create_table "welfare_notes", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "internal", default: true, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "welfare_case_id", null: false
    t.index ["internal"], name: "index_welfare_notes_on_internal"
    t.index ["user_id"], name: "index_welfare_notes_on_user_id"
    t.index ["welfare_case_id", "created_at"], name: "index_welfare_notes_on_welfare_case_id_and_created_at"
    t.index ["welfare_case_id"], name: "index_welfare_notes_on_welfare_case_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcement_reads", "announcements"
  add_foreign_key "announcement_reads", "users"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "users"
  add_foreign_key "attendances", "users", column: "checked_in_by_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "documents", "document_categories"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "event_registrations", "events"
  add_foreign_key "event_registrations", "users"
  add_foreign_key "events", "event_categories"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "family_members", "member_profiles"
  add_foreign_key "finance_transactions", "finance_categories"
  add_foreign_key "finance_transactions", "users", column: "approved_by_id"
  add_foreign_key "finance_transactions", "users", column: "recorded_by_id"
  add_foreign_key "meeting_minute_attendances", "meeting_minutes"
  add_foreign_key "meeting_minute_attendances", "users"
  add_foreign_key "meeting_minutes", "users", column: "uploaded_by_id"
  add_foreign_key "member_profiles", "users"
  add_foreign_key "membership_payments", "family_members"
  add_foreign_key "membership_payments", "membership_plans"
  add_foreign_key "membership_payments", "payment_batches"
  add_foreign_key "membership_payments", "users"
  add_foreign_key "membership_payments", "users", column: "approved_by_id"
  add_foreign_key "membership_payments", "users", column: "receipt_shared_by_id"
  add_foreign_key "membership_plans", "membership_plan_types"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "payment_batches", "users"
  add_foreign_key "payment_batches", "users", column: "approved_by_id"
  add_foreign_key "volunteer_signups", "users"
  add_foreign_key "volunteer_signups", "volunteer_slots"
  add_foreign_key "volunteer_slots", "events"
  add_foreign_key "welfare_attachments", "users", column: "uploaded_by_id"
  add_foreign_key "welfare_attachments", "welfare_cases"
  add_foreign_key "welfare_cases", "users"
  add_foreign_key "welfare_cases", "users", column: "assigned_to_id"
  add_foreign_key "welfare_cases", "welfare_categories"
  add_foreign_key "welfare_notes", "users"
  add_foreign_key "welfare_notes", "welfare_cases"
end
