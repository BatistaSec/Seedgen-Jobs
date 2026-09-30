const fs = require('fs');
const { marked } = require('marked');
const htmlDocx = require('html-docx-js');

if (process.argv.length < 4) {
    console.error('Usage: node generate_docx.js <input.md> <output.docx>');
    process.exit(1);
}

const inputPath = process.argv[2];
const outputPath = process.argv[3];

try {
    const mdContent = fs.readFileSync(inputPath, 'utf8');
    
    // Converte Markdown para HTML
    const htmlContent = marked.parse(mdContent);
    
    // Envelopa em uma estrutura HTML válida que o html-docx-js consiga renderizar bem
    const docxHtml = `
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: 'Arial', sans-serif; font-size: 11pt; }
            h1 { font-size: 16pt; color: #000000; text-align: center; }
            h2 { font-size: 14pt; color: #333333; border-bottom: 1px solid #cccccc; margin-top: 15px; }
            p, li { line-height: 1.5; }
            ul { margin-bottom: 10px; }
        </style>
    </head>
    <body>
        ${htmlContent}
    </body>
    </html>
    `;

    // Converte para buffer docx
    const docxBuffer = htmlDocx.asBlob(docxHtml);
    
    // Escreve o arquivo
    fs.writeFileSync(outputPath, docxBuffer);
    console.log(`[SUCESSO] Arquivo DOCX gerado em: ${outputPath}`);
} catch (error) {
    console.error('[ERRO] Falha ao gerar DOCX:', error);
    process.exit(1);
}
