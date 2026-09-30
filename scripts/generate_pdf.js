const markdownpdf = require("markdown-pdf");
const fs = require("fs");
const path = require("path");

// Recebe argumentos de linha de comando: 
// argv[2] = input path (markdown)
// argv[3] = output path (pdf)
const inputPath = process.argv[2];
const outputPath = process.argv[3];

if (!inputPath || !outputPath) {
  console.error("Uso: node generate_pdf.js <caminho_entrada_md> <caminho_saida_pdf>");
  process.exit(1);
}

if (!fs.existsSync(inputPath)) {
  console.error(`Arquivo não encontrado: ${inputPath}`);
  process.exit(1);
}

const pdfOptions = {
  paperBorder: "2cm",
  cssPath: path.join(__dirname, "resume-style.css") // Opcional
};

markdownpdf(pdfOptions).from(inputPath).to(outputPath, function () {
  console.log(`PDF gerado com sucesso em: ${outputPath}`);
});
