# Infra

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/ 
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

---

# 📘 Guía de Aprendizaje: Elixir y Phoenix

Esta sección está diseñada para explicarte **cómo funciona Elixir**, su sintaxis, y cómo construir aplicaciones completas (Frontend y Backend) utilizando el framework **Phoenix**.

## 1. Fundamentos de Elixir

Elixir es un lenguaje funcional que corre sobre la **BEAM** (la máquina virtual de Erlang), diseñada para sistemas distribuidos y tolerantes a fallos.

### Sintaxis Básica

Todo en Elixir gira en torno a **Módulos** y **Funciones**.

```elixir
defmodule Mate do
  # Función pública
  def suma(a, b) do
    a + b
  end

  # Función privada (solo accesible dentro de este módulo)
  defp resta(a, b), do: a - b
end
```

### El Operador Pipe (`|>`)

Es la característica más famosa de Elixir. Toma el resultado de la expresión anterior y lo pasa como **primer argumento** a la siguiente función.

**Sin Pipe:**
```elixir
String.upcase(String.trim("  hola  "))
```

**Con Pipe:**
```elixir
"  hola  "
|> String.trim()
|> String.upcase()
# Resultado: "HOLA"
```

### Pattern Matching (Coincidencia de Patrones)

El signo `=` no es solo asignación, es una coincidencia.

```elixir
# Desestructuración de Mapas
%{nombre: n} = %{nombre: "Adam", edad: 30}
# n ahora vale "Adam"

# En funciones (muy poderoso para control de flujo)
def saludar(%{idioma: "es"}), do: "Hola"
def saludar(%{idioma: "en"}), do: "Hello"
```

---

## 2. Arquitectura de Phoenix (Backend & Frontend)

Phoenix no es MVC tradicional, pero se le parece. Se divide principalmente en:

1.  **Endpoint**: Donde llega la petición HTTP/Websocket.
2.  **Router**: Decide a dónde enviar la petición (`lib/infra_web/router.ex`).
3.  **Controllers / LiveViews**: Manejan la lógica de la vista.
4.  **Contexts (Contextos)**: La lógica de negocio pura y acceso a datos (`lib/infra/`).
5.  **Views / Templates**: Lo que ve el usuario (HTML/JSON).

### Estructura de Carpetas

*   `assets/`: Frontend (Javascript, CSS, imágenes).
*   `lib/infra/`: **Backend puro**. Aquí van tus esquemas de base de datos, reglas de negocio y contextos. No sabe nada de HTTP ni de la web.
*   `lib/infra_web/`: **Capa Web**. Aquí viven el router, controladores, LiveViews y plantillas.
*   `priv/repo/`: Migraciones de base de datos.
*   `test/`: Tests automatizados (¡muy importantes en Elixir!).

---

## 3. Backend: Gestionando Datos (Ecto)

Phoenix usa **Ecto** para interactuar con la base de datos.

### Schemas (Esquemas)
Definen la estructura de tu tabla en la base de datos.

```elixir
defmodule Infra.Blog.Post do
  use Ecto.Schema

  schema "posts" do
    field :titulo, :string
    field :cuerpo, :string
    timestamps()
  end
end
```

### Changesets (Conjuntos de Cambios)
Validan los datos antes de guardarlos.

```elixir
def changeset(post, attrs) do
  post
  |> cast(attrs, [:titulo, :cuerpo])
  |> validate_required([:titulo])
end
```

### Contextos (Contexts)
Es la API pública de tu backend. Un contexto agrupa funcionalidades relacionadas. Por ejemplo, un contexto `Blog` gestionaría `Posts` y `Comentarios`.

```elixir
defmodule Infra.Blog do
  alias Infra.Repo
  alias Infra.Blog.Post

  def crear_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end
end
```

---

## 4. Frontend: Phoenix LiveView

En Phoenix moderno, el Frontend se construye principalmente con **LiveView**. LiveView te permite escribir interfaces ricas e interactivas **escribiendo código en el servidor (Elixir)**, sincronizando el estado con el navegador vía WebSockets automáticamente.

### Cómo funciona un LiveView

Un LiveView tiene 3 partes clave:

1.  `mount/3`: Inicializa el estado (asignaciones).
2.  `render/1`: Define el HTML (usando sintaxis HEEx `~H`).
3.  `handle_event/3`: Maneja interacciones del usuario (clicks, formularios).

```elixir
defmodule InfraWeb.ContadorLive do
  use InfraWeb, :live_view

  # 1. Inicializar estado
  def mount(_params, _session, socket) do
    {:ok, assign(socket, cuenta: 0)}
  end

  # 2. Renderizar UI
  def render(assigns) do
    ~H"""
    <div>
      <h1>La cuenta es: <%= @cuenta %></h1>
      <button phx-click="incrementar">Suma +1</button>
    </div>
    """
  end

  # 3. Manejar eventos
  def handle_event("incrementar", _params, socket) do
    {:noreply, update(socket, :cuenta, &(&1 + 1))}
  end
end
```

### Tailwind CSS
Este proyecto ya tiene Tailwind configurado. Puedes usar clases directamente en tu HTML:
`<div class="bg-blue-500 text-white p-4">Hola</div>`

---

## 5. Cómo crear una nueva funcionalidad (Workflow)

Si quieres hacer una app, por ejemplo, un "Todo List", seguirías estos pasos:

1.  **Generar el Contexto y Schema (Backend)**:
    ```bash
    mix phx.gen.context Tareas Tarea tareas titulo:string completado:boolean
    ```
    *   `Tareas`: El nombre del Contexto (Lógica de negocio).
    *   `Tarea`: El nombre del Schema (Modelo de datos).
    *   `tareas`: El nombre de la tabla en la DB.

2.  **Correr la migración**:
    ```bash
    mix ecto.migrate
    ```

3.  **Generar el Frontend (LiveView)**:
    ```bash
    mix phx.gen.live Tareas Tarea tareas titulo:string completado:boolean
    ```
    *(Nota: `phx.gen.live` puede generar todo junto con el contexto si usas ese comando desde el principio)*.

4.  **Añadir la ruta**:
    Abre `lib/infra_web/router.ex` y añade:
    ```elixir
    scope "/", InfraWeb do
      pipe_through :browser
      live "/tareas", TareaLive.Index, :index
    end
    ```

5.  **Probar**:
    Ve a `localhost:4000/tareas`.

---

## Recursos Adicionales

*   **HexDocs**: La documentación de Elixir es excelente.
*   **Elixir School**: Tutoriales paso a paso en español.
*   **Phoenix Guides**: Guías oficiales de Phoenix.
