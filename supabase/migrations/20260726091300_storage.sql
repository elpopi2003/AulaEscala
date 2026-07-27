-- ============================================================================
-- 20260726091300_storage
-- Buckets y politicas (§5).
--
--   media-public  -> portadas, miniaturas de paso, imagenes del feed, galeria
--                    del resultado final. Bucket PUBLICO.
--   media-private -> imagenes del cuerpo de los pasos. Bucket PRIVADO.
--   materials     -> materiales descargables. Bucket PRIVADO, siempre Pro+.
--
-- El contenido de pago NUNCA se sirve con URL publica permanente: se firma con
-- signed URLs de vida corta tras verificar el tramo (§13).
--
-- Convencion de rutas (la impone el cliente al subir y la leen las politicas):
--   media-public  : {author_id}/projects/{project_id}/...
--   media-private : {author_id}/steps/{step_id}/...
--   materials     : {author_id}/projects/{project_id}/...
-- El primer segmento es siempre el propietario, que es lo que permite validar
-- la escritura sin consultar otras tablas.
-- ============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('media-public',  'media-public',  true,  10485760,
   array['image/jpeg','image/png','image/webp','image/avif']),
  ('media-private', 'media-private', false, 10485760,
   array['image/jpeg','image/png','image/webp','image/avif']),
  ('materials',     'materials',     false, 52428800,
   array['application/pdf','application/zip','image/jpeg','image/png','text/plain'])
on conflict (id) do nothing;

-- ── media-public ────────────────────────────────────────────────────────────
create policy "media-public: lectura de todos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'media-public');

create policy "media-public: sube el modelista en su carpeta"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media-public'
    and (select public.is_at_least('modelista'))
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "media-public: gestiona su propietario"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media-public'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'media-public'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "media-public: borra su propietario"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media-public'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ── media-private — imagenes del cuerpo de los pasos ────────────────────────
-- La lectura pasa por el MISMO predicado que la tabla step_bodies. Si la
-- politica de Storage y la de la tabla divergieran, tendriamos una fuga por
-- una via sin la otra: es justo el escenario que el test de no-fuga vigila
-- (§13, "por ninguna via: consulta directa, feed, busqueda, Storage").
create policy "media-private: lee quien puede leer el cuerpo del paso"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'media-private'
    and exists (
      select 1
        from public.media m
       where m.storage_path = storage.objects.name
         and m.step_id is not null
         and public.can_view_step_body(m.step_id)
    )
  );

create policy "media-private: sube el modelista en su carpeta"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'media-private'
    and (select public.is_at_least('modelista'))
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "media-private: gestiona su propietario"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'media-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'media-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "media-private: borra su propietario"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'media-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ── materials — siempre Pro+ ────────────────────────────────────────────────
create policy "materials: descarga pro o el autor"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'materials'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text   -- el autor
      or exists (
        select 1
          from public.materials mt
         where mt.storage_path = storage.objects.name
           and public.is_at_least('pro')
           and public.can_view_project(mt.project_id)
      )
    )
  );

create policy "materials: sube el modelista en su carpeta"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'materials'
    and (select public.is_at_least('modelista'))
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "materials: gestiona su propietario"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "materials: borra su propietario"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
