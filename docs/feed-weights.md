# Pesos del feed de progreso

El feed es el diferenciador del producto (§2, §6): **prioriza el progreso real** —
pasos nuevos, builds terminados— sobre la publicación genérica. Y es además el motor
de conversión: el usuario gratuito ve el evento, y al abrirlo encuentra el muro.

## Cómo se calcula

El `score` se **precomputa en la escritura** con un trigger y no se recalcula nunca
(§3.5). El feed es entonces una consulta trivial sobre un índice:

```sql
select * from activity order by score desc, created_at desc limit 30;
--    índice: activity_feed_idx (score desc, created_at desc)
```

La fórmula (`public.activity_compute_score`):

```
score = peso_del_evento + (segundos_epoch / 45000)
```

El término temporal **siempre crece**, así que lo nuevo sube solo, sin trabajo de
mantenimiento ni recálculos periódicos. Es el modelo de *hot ranking* clásico.

**45 000 s = 12,5 h.** Ese es el precio de un punto de peso: un evento con peso 3
mantiene la ventaja sobre uno de peso 1 durante 25 horas.

## Tabla de pesos

Vive en `public.activity_weights` — se afina con un `update`, sin desplegar nada.

| Evento | Peso | Ventaja sobre `project_updated` | Por qué |
|---|:---:|:---:|---|
| `project_finished` | **4.0** | 37,5 h | Un build terminado es el evento estrella: cierra una historia que la comunidad venía siguiendo |
| `step_published` | **3.0** | 25 h | El progreso real. Es el núcleo del feed y el que lleva al muro de Pro |
| `project_published` | **2.0** | 12,5 h | Una bitácora nueva importa, pero aún no demuestra constancia |
| `project_updated` | **1.0** | — | Publicación genérica: pesa lo mínimo, justo lo que §6 quiere evitar que domine |

## Cómo afinarlo

```sql
update public.activity_weights set weight = 3.5 where type = 'step_published';
```

**Sólo afecta a los eventos futuros.** El `score` de los existentes es histórico y no
se recalcula. Si hace falta reescribir el pasado:

```sql
update public.activity a
   set score = public.activity_compute_score(a.type, a.created_at);
```

## Reglas al tocar esto

- **Nunca calcular el score en lectura.** Rompe el índice y convierte el feed en un
  `seq scan` sobre una tabla que sólo crece.
- **`snapshot` es teaser-seguro.** Sólo lo que pinta la tarjeta: título, miniatura,
  autor, proyecto padre y el flag `is_paywalled`. **Nunca** el cuerpo del paso — el
  feed es público y cacheable con ISR, así que cualquier cosa que entre ahí es pública
  de facto.
- **Al añadir un `activity_type`** hay que insertar su fila en `activity_weights`. Si
  falta, `activity_compute_score` cae al valor por defecto `1.0` en vez de fallar.
