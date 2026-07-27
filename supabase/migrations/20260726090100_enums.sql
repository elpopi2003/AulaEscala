-- ============================================================================
-- 20260726090100_enums
-- Tipos enumerados. Se prefieren a text+CHECK porque `supabase gen types`
-- los emite como uniones de TypeScript, que alimentan los esquemas Zod
-- compartidos (§11 /packages/shared).
-- ============================================================================

-- Tramos del modelo freemium (§4). El orden textual NO implica jerarquia:
-- la jerarquia la define public.tier_rank().
create type public.subscription_tier as enum ('subscriber', 'pro', 'modelista');

-- Espejo de los estados de suscripcion de Stripe.
create type public.subscription_status as enum (
  'trialing', 'active', 'past_due', 'canceled',
  'incomplete', 'incomplete_expired', 'unpaid', 'paused'
);

-- Rol de aplicacion. `admin` accede al panel de operador (§9).
create type public.app_role as enum ('user', 'moderator', 'admin');

-- draft / published (§7.1: hay borradores, no hay moderacion previa).
create type public.content_status as enum ('draft', 'published');

-- Estado del build mostrado en la portada del proyecto.
create type public.build_status as enum ('wip', 'finished');

create type public.difficulty_level as enum ('iniciacion', 'intermedio', 'avanzado', 'experto');

-- Revision de taxonomia (§7.2): las tecnicas se publican directas pero quedan
-- marcadas para que el operador las revise y funda duplicados.
create type public.moderation_status as enum ('pending_review', 'approved', 'merged', 'rejected');

create type public.media_kind as enum ('image', 'video');

-- Eventos del feed de progreso (§6).
create type public.activity_type as enum (
  'step_published',
  'project_published',
  'project_finished',
  'project_updated'
);

create type public.notification_type as enum (
  'new_follower',
  'new_comment',
  'comment_reply',
  'comment_like',
  'new_message',
  'followed_step_published',
  'followed_project_finished'
);

create type public.report_target_type as enum ('project', 'step', 'comment', 'profile', 'message');

create type public.report_status as enum ('open', 'reviewing', 'actioned', 'dismissed');
