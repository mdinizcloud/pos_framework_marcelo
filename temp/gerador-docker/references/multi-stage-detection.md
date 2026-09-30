# Detecção de multi-stage por stack

Regra geral: multi-stage é justificado quando existe artefato compilável/transpilável/bundle que pode ser copiado pro runtime sem carregar a toolchain de build na imagem final. Stack só interpretado, sem etapa de build, não precisa.

- **Node.js:** ler `package.json` (ou `src/package.json`). Se houver `typescript`, `ts-node`, `webpack`, `esbuild`, `vite`, `rollup`, `parcel`, `next`, `nest` em `dependencies`/`devDependencies` → tem build step, multi-stage recomendado. Node puro sem esses pacotes → proibido multi-stage (só adiciona complexidade).
- **Python:** usar multi-stage se houver compilação de extensão nativa (Cython, `build-system` com wheel compilado) **ou** se alguma dependência em `requirements.txt`/`pyproject.toml` exigir `gcc`/`build-essential` pra instalar (sem wheel pré-compilado pra plataforma alvo — comum em Alpine/musl, ver Regra 2 sobre exceção de tag). Nesses casos, stage builder instala com toolchain de compilação, stage runtime copia só o virtualenv/site-packages. Framework puro sem nenhuma dessas condições (Flask/Django/FastAPI com deps só wheel puro) → single stage com `pip install --no-cache-dir`.
- **Go:** **sempre** multi-stage — stage builder compila binário estático (`CGO_ENABLED=0 go build`), stage runtime usa `scratch` ou `distroless` copiando só o binário.
- **Java (Maven/Gradle):** **sempre** multi-stage — stage builder roda `mvn package`/`gradle build`, stage runtime copia só o `.jar` pra imagem JRE (`eclipse-temurin:<versão>-jre-alpine`).
- **.NET:** **sempre** multi-stage — stage builder com SDK (`dotnet publish`), stage runtime com imagem `aspnet` runtime-only.
- **Rust:** **sempre** multi-stage — stage builder compila release binary, stage runtime `scratch`/`distroless`/`debian-slim`.
- **PHP:** geralmente não precisa (interpretado). Só usar stage separado se houver build de assets front-end (webpack/vite) — nesse caso, stage de assets isolado do stage PHP-FPM.
- **Ruby:** análogo ao Python — multi-stage só se alguma gem exigir compilação nativa (`native extension`, `mkmf`) sem gem pré-compilada pra plataforma alvo.
- **Stack não listada:** aplicar a regra geral do primeiro parágrafo.
