// Generado por `pnpm db:types`. NO editar a mano.
// Se regenera tras cualquier cambio de esquema; CI falla si queda desfasado.
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      activity: {
        Row: {
          actor_id: string
          created_at: string
          id: string
          project_id: string | null
          score: number
          snapshot: Json
          step_id: string | null
          type: Database["public"]["Enums"]["activity_type"]
        }
        Insert: {
          actor_id: string
          created_at?: string
          id?: string
          project_id?: string | null
          score?: number
          snapshot?: Json
          step_id?: string | null
          type: Database["public"]["Enums"]["activity_type"]
        }
        Update: {
          actor_id?: string
          created_at?: string
          id?: string
          project_id?: string | null
          score?: number
          snapshot?: Json
          step_id?: string | null
          type?: Database["public"]["Enums"]["activity_type"]
        }
        Relationships: [
          {
            foreignKeyName: "activity_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activity_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activity_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "steps"
            referencedColumns: ["id"]
          },
        ]
      }
      activity_weights: {
        Row: {
          type: Database["public"]["Enums"]["activity_type"]
          updated_at: string
          weight: number
        }
        Insert: {
          type: Database["public"]["Enums"]["activity_type"]
          updated_at?: string
          weight: number
        }
        Update: {
          type?: Database["public"]["Enums"]["activity_type"]
          updated_at?: string
          weight?: number
        }
        Relationships: []
      }
      app_config: {
        Row: {
          free_preview_steps: number
          id: boolean
          updated_at: string
        }
        Insert: {
          free_preview_steps?: number
          id?: boolean
          updated_at?: string
        }
        Update: {
          free_preview_steps?: number
          id?: boolean
          updated_at?: string
        }
        Relationships: []
      }
      comment_likes: {
        Row: {
          comment_id: string
          created_at: string
          user_id: string
        }
        Insert: {
          comment_id: string
          created_at?: string
          user_id: string
        }
        Update: {
          comment_id?: string
          created_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comment_likes_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_likes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          author_id: string
          body: string
          created_at: string
          id: string
          parent_id: string | null
          project_id: string | null
          step_id: string | null
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          created_at?: string
          id?: string
          parent_id?: string | null
          project_id?: string | null
          step_id?: string | null
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          created_at?: string
          id?: string
          parent_id?: string | null
          project_id?: string | null
          step_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "steps"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_participants: {
        Row: {
          conversation_id: string
          joined_at: string
          last_read_at: string | null
          user_id: string
        }
        Insert: {
          conversation_id: string
          joined_at?: string
          last_read_at?: string | null
          user_id: string
        }
        Update: {
          conversation_id?: string
          joined_at?: string
          last_read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_participants_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "conversation_participants_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          last_message_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          last_message_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          last_message_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      favorites: {
        Row: {
          created_at: string
          project_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          project_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          project_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      follows: {
        Row: {
          created_at: string
          followee_id: string
          follower_id: string
        }
        Insert: {
          created_at?: string
          followee_id: string
          follower_id: string
        }
        Update: {
          created_at?: string
          followee_id?: string
          follower_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "follows_followee_id_fkey"
            columns: ["followee_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "follows_follower_id_fkey"
            columns: ["follower_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      materials: {
        Row: {
          byte_size: number | null
          created_at: string
          filename: string
          id: string
          mime: string | null
          position: number
          project_id: string
          storage_path: string
        }
        Insert: {
          byte_size?: number | null
          created_at?: string
          filename: string
          id?: string
          mime?: string | null
          position?: number
          project_id: string
          storage_path: string
        }
        Update: {
          byte_size?: number | null
          created_at?: string
          filename?: string
          id?: string
          mime?: string | null
          position?: number
          project_id?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "materials_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      media: {
        Row: {
          alt_text: string | null
          byte_size: number | null
          created_at: string
          height: number | null
          id: string
          is_private: boolean
          kind: Database["public"]["Enums"]["media_kind"]
          mime: string | null
          owner_id: string
          position: number
          project_id: string | null
          step_id: string | null
          storage_path: string
          width: number | null
        }
        Insert: {
          alt_text?: string | null
          byte_size?: number | null
          created_at?: string
          height?: number | null
          id?: string
          is_private?: boolean
          kind?: Database["public"]["Enums"]["media_kind"]
          mime?: string | null
          owner_id: string
          position?: number
          project_id?: string | null
          step_id?: string | null
          storage_path: string
          width?: number | null
        }
        Update: {
          alt_text?: string | null
          byte_size?: number | null
          created_at?: string
          height?: number | null
          id?: string
          is_private?: boolean
          kind?: Database["public"]["Enums"]["media_kind"]
          mime?: string | null
          owner_id?: string
          position?: number
          project_id?: string | null
          step_id?: string | null
          storage_path?: string
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "media_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "media_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "steps"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          body: string
          conversation_id: string
          created_at: string
          id: string
          read_at: string | null
          sender_id: string
        }
        Insert: {
          body: string
          conversation_id: string
          created_at?: string
          id?: string
          read_at?: string | null
          sender_id: string
        }
        Update: {
          body?: string
          conversation_id?: string
          created_at?: string
          id?: string
          read_at?: string | null
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          emailed_at: string | null
          id: string
          payload: Json
          read_at: string | null
          type: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Insert: {
          created_at?: string
          emailed_at?: string | null
          id?: string
          payload?: Json
          read_at?: string | null
          type: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Update: {
          created_at?: string
          emailed_at?: string | null
          id?: string
          payload?: Json
          read_at?: string | null
          type?: Database["public"]["Enums"]["notification_type"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          created_at: string
          display_name: string
          id: string
          links: Json
          location: string | null
          preferred_scales: string[]
          preferred_subjects: string[]
          role: Database["public"]["Enums"]["app_role"]
          slug: string
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name: string
          id: string
          links?: Json
          location?: string | null
          preferred_scales?: string[]
          preferred_subjects?: string[]
          role?: Database["public"]["Enums"]["app_role"]
          slug: string
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string
          id?: string
          links?: Json
          location?: string | null
          preferred_scales?: string[]
          preferred_subjects?: string[]
          role?: Database["public"]["Enums"]["app_role"]
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
      project_techniques: {
        Row: {
          project_id: string
          technique_id: string
        }
        Insert: {
          project_id: string
          technique_id: string
        }
        Update: {
          project_id?: string
          technique_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_techniques_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_techniques_technique_id_fkey"
            columns: ["technique_id"]
            isOneToOne: false
            referencedRelation: "techniques"
            referencedColumns: ["id"]
          },
        ]
      }
      projects: {
        Row: {
          author_id: string
          body: string | null
          build_status: Database["public"]["Enums"]["build_status"]
          cover_url: string | null
          created_at: string
          difficulty: Database["public"]["Enums"]["difficulty_level"] | null
          finished_at: string | null
          id: string
          kit_ref: string | null
          locale: string
          manufacturer: string | null
          published_at: string | null
          scale_id: string | null
          search_vector: unknown
          slug: string
          status: Database["public"]["Enums"]["content_status"]
          subject_id: string | null
          subtitle: string | null
          title: string
          translation_group_id: string
          updated_at: string
        }
        Insert: {
          author_id: string
          body?: string | null
          build_status?: Database["public"]["Enums"]["build_status"]
          cover_url?: string | null
          created_at?: string
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          finished_at?: string | null
          id?: string
          kit_ref?: string | null
          locale?: string
          manufacturer?: string | null
          published_at?: string | null
          scale_id?: string | null
          search_vector?: unknown
          slug: string
          status?: Database["public"]["Enums"]["content_status"]
          subject_id?: string | null
          subtitle?: string | null
          title: string
          translation_group_id?: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string | null
          build_status?: Database["public"]["Enums"]["build_status"]
          cover_url?: string | null
          created_at?: string
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          finished_at?: string | null
          id?: string
          kit_ref?: string | null
          locale?: string
          manufacturer?: string | null
          published_at?: string | null
          scale_id?: string | null
          search_vector?: unknown
          slug?: string
          status?: Database["public"]["Enums"]["content_status"]
          subject_id?: string | null
          subtitle?: string | null
          title?: string
          translation_group_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "projects_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "projects_scale_id_fkey"
            columns: ["scale_id"]
            isOneToOne: false
            referencedRelation: "scales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "projects_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          created_at: string
          id: string
          notes: string | null
          reason: string
          reporter_id: string | null
          resolved_at: string | null
          resolved_by: string | null
          status: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: Database["public"]["Enums"]["report_target_type"]
        }
        Insert: {
          created_at?: string
          id?: string
          notes?: string | null
          reason: string
          reporter_id?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: Database["public"]["Enums"]["report_target_type"]
        }
        Update: {
          created_at?: string
          id?: string
          notes?: string | null
          reason?: string
          reporter_id?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: Database["public"]["Enums"]["report_status"]
          target_id?: string
          target_type?: Database["public"]["Enums"]["report_target_type"]
        }
        Relationships: [
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      scales: {
        Row: {
          created_at: string
          id: string
          name: string
          position: number
          ratio: number
          slug: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          position?: number
          ratio: number
          slug: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          position?: number
          ratio?: number
          slug?: string
        }
        Relationships: []
      }
      step_bodies: {
        Row: {
          body: string | null
          created_at: string
          search_vector: unknown
          step_id: string
          tip: string | null
          updated_at: string
        }
        Insert: {
          body?: string | null
          created_at?: string
          search_vector?: unknown
          step_id: string
          tip?: string | null
          updated_at?: string
        }
        Update: {
          body?: string | null
          created_at?: string
          search_vector?: unknown
          step_id?: string
          tip?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "step_bodies_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: true
            referencedRelation: "steps"
            referencedColumns: ["id"]
          },
        ]
      }
      step_techniques: {
        Row: {
          step_id: string
          technique_id: string
        }
        Insert: {
          step_id: string
          technique_id: string
        }
        Update: {
          step_id?: string
          technique_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "step_techniques_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "steps"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "step_techniques_technique_id_fkey"
            columns: ["technique_id"]
            isOneToOne: false
            referencedRelation: "techniques"
            referencedColumns: ["id"]
          },
        ]
      }
      steps: {
        Row: {
          created_at: string
          duration_minutes: number | null
          id: string
          locale: string
          position: number
          project_id: string
          published_at: string | null
          search_vector: unknown
          status: Database["public"]["Enums"]["content_status"]
          thumb_url: string | null
          title: string
          translation_group_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          duration_minutes?: number | null
          id?: string
          locale?: string
          position: number
          project_id: string
          published_at?: string | null
          search_vector?: unknown
          status?: Database["public"]["Enums"]["content_status"]
          thumb_url?: string | null
          title: string
          translation_group_id?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          duration_minutes?: number | null
          id?: string
          locale?: string
          position?: number
          project_id?: string
          published_at?: string | null
          search_vector?: unknown
          status?: Database["public"]["Enums"]["content_status"]
          thumb_url?: string | null
          title?: string
          translation_group_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "steps_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      subjects: {
        Row: {
          created_at: string
          id: string
          name: string
          position: number
          slug: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          position?: number
          slug: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          position?: number
          slug?: string
        }
        Relationships: []
      }
      subscriptions: {
        Row: {
          cancel_at_period_end: boolean
          created_at: string
          current_period_end: string | null
          status: Database["public"]["Enums"]["subscription_status"]
          stripe_customer_id: string | null
          stripe_subscription_id: string | null
          tier: Database["public"]["Enums"]["subscription_tier"]
          updated_at: string
          user_id: string
        }
        Insert: {
          cancel_at_period_end?: boolean
          created_at?: string
          current_period_end?: string | null
          status?: Database["public"]["Enums"]["subscription_status"]
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          tier?: Database["public"]["Enums"]["subscription_tier"]
          updated_at?: string
          user_id: string
        }
        Update: {
          cancel_at_period_end?: boolean
          created_at?: string
          current_period_end?: string | null
          status?: Database["public"]["Enums"]["subscription_status"]
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          tier?: Database["public"]["Enums"]["subscription_tier"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      techniques: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          merged_into_id: string | null
          moderation_status: Database["public"]["Enums"]["moderation_status"]
          name: string
          search_vector: unknown
          slug: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          merged_into_id?: string | null
          moderation_status?: Database["public"]["Enums"]["moderation_status"]
          name: string
          search_vector?: unknown
          slug: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          merged_into_id?: string | null
          moderation_status?: Database["public"]["Enums"]["moderation_status"]
          name?: string
          search_vector?: unknown
          slug?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "techniques_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "techniques_merged_into_id_fkey"
            columns: ["merged_into_id"]
            isOneToOne: false
            referencedRelation: "techniques"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      activity_compute_score: {
        Args: {
          p_created_at: string
          p_type: Database["public"]["Enums"]["activity_type"]
        }
        Returns: number
      }
      build_project_snapshot: { Args: { p_project_id: string }; Returns: Json }
      build_step_snapshot: { Args: { p_step_id: string }; Returns: Json }
      can_receive_messages: { Args: { p_user_id: string }; Returns: boolean }
      can_view_comment_target: {
        Args: { p_project_id: string; p_step_id: string }
        Returns: boolean
      }
      can_view_project: { Args: { p_project_id: string }; Returns: boolean }
      can_view_step: { Args: { p_step_id: string }; Returns: boolean }
      can_view_step_body: { Args: { p_step_id: string }; Returns: boolean }
      create_step: {
        Args: {
          p_body?: string
          p_duration_minutes?: number
          p_position?: number
          p_project_id: string
          p_status?: Database["public"]["Enums"]["content_status"]
          p_technique_ids?: string[]
          p_thumb_url?: string
          p_tip?: string
          p_title: string
        }
        Returns: string
      }
      enqueue_notification: {
        Args: {
          p_payload?: Json
          p_type: Database["public"]["Enums"]["notification_type"]
          p_user_id: string
        }
        Returns: string
      }
      free_preview_steps: { Args: never; Returns: number }
      is_admin: { Args: never; Returns: boolean }
      is_at_least: {
        Args: { min_tier: Database["public"]["Enums"]["subscription_tier"] }
        Returns: boolean
      }
      is_conversation_participant: {
        Args: { p_conversation_id: string }
        Returns: boolean
      }
      reorder_steps: {
        Args: { p_project_id: string; p_step_ids: string[] }
        Returns: undefined
      }
      search_message_recipients: {
        Args: { max_results?: number; query: string }
        Returns: {
          avatar_url: string
          display_name: string
          id: string
          slug: string
        }[]
      }
      search_public: {
        Args: { max_results?: number; query: string }
        Returns: {
          id: string
          kind: string
          project_id: string
          rank: number
          slug: string
          thumb_url: string
          title: string
        }[]
      }
      search_step_bodies: {
        Args: { max_results?: number; query: string }
        Returns: {
          headline: string
          project_id: string
          rank: number
          step_id: string
          step_title: string
        }[]
      }
      slugify: { Args: { value: string }; Returns: string }
      suggest_similar_techniques: {
        Args: {
          candidate: string
          max_results?: number
          min_similarity?: number
        }
        Returns: {
          id: string
          name: string
          similarity: number
          slug: string
        }[]
      }
      tier_of: {
        Args: { p_user_id: string }
        Returns: Database["public"]["Enums"]["subscription_tier"]
      }
      tier_rank: {
        Args: { t: Database["public"]["Enums"]["subscription_tier"] }
        Returns: number
      }
      update_step: {
        Args: {
          p_body?: string
          p_duration_minutes?: number
          p_status?: Database["public"]["Enums"]["content_status"]
          p_step_id: string
          p_technique_ids?: string[]
          p_thumb_url?: string
          p_tip?: string
          p_title?: string
        }
        Returns: undefined
      }
      user_tier: {
        Args: never
        Returns: Database["public"]["Enums"]["subscription_tier"]
      }
    }
    Enums: {
      activity_type:
        | "step_published"
        | "project_published"
        | "project_finished"
        | "project_updated"
      app_role: "user" | "moderator" | "admin"
      build_status: "wip" | "finished"
      content_status: "draft" | "published"
      difficulty_level: "iniciacion" | "intermedio" | "avanzado" | "experto"
      media_kind: "image" | "video"
      moderation_status: "pending_review" | "approved" | "merged" | "rejected"
      notification_type:
        | "new_follower"
        | "new_comment"
        | "comment_reply"
        | "comment_like"
        | "new_message"
        | "followed_step_published"
        | "followed_project_finished"
      report_status: "open" | "reviewing" | "actioned" | "dismissed"
      report_target_type: "project" | "step" | "comment" | "profile" | "message"
      subscription_status:
        | "trialing"
        | "active"
        | "past_due"
        | "canceled"
        | "incomplete"
        | "incomplete_expired"
        | "unpaid"
        | "paused"
      subscription_tier: "subscriber" | "pro" | "modelista"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      activity_type: [
        "step_published",
        "project_published",
        "project_finished",
        "project_updated",
      ],
      app_role: ["user", "moderator", "admin"],
      build_status: ["wip", "finished"],
      content_status: ["draft", "published"],
      difficulty_level: ["iniciacion", "intermedio", "avanzado", "experto"],
      media_kind: ["image", "video"],
      moderation_status: ["pending_review", "approved", "merged", "rejected"],
      notification_type: [
        "new_follower",
        "new_comment",
        "comment_reply",
        "comment_like",
        "new_message",
        "followed_step_published",
        "followed_project_finished",
      ],
      report_status: ["open", "reviewing", "actioned", "dismissed"],
      report_target_type: ["project", "step", "comment", "profile", "message"],
      subscription_status: [
        "trialing",
        "active",
        "past_due",
        "canceled",
        "incomplete",
        "incomplete_expired",
        "unpaid",
        "paused",
      ],
      subscription_tier: ["subscriber", "pro", "modelista"],
    },
  },
} as const
