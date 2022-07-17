const underscore = require('underscore');
const process = require('process');
const fs = require('fs');
const prettier = require('prettier');
const prettierPluginSolidity = require('prettier-plugin-solidity');
const {exit} = require("process");

const myPlugin = {
    languages: {
        name: 'Solidity-mod', parsers: 'solidity-mod-parse',
    },
    parsers: {
        'solidity-mod-parse': {
            parse: (text, _parsers, options) => {
                const ast = prettierPluginSolidity.parsers["solidity-parse"].parse(text, _parsers, options);

                for (const contractKey in ast.children) {
                    const contract = ast.children[contractKey];
                    if (contract.type !== "ContractDefinition") continue;
                    console.log(`Find contract: ${contract.name}.`);
                    const knownStateTx = {};
                    const addStateTx = (dict, type, name) => {
                        if (!(name in dict)) {
                            dict[name] = {};
                        }
                        if (!(type in dict[name])) {
                            dict[name][type] = true;
                        } else {
                            throw new Error(`'${type}' of ${name} shown more than once.`)
                        }
                    }

                    for (const key in contract.subNodes) {
                        const child = contract.subNodes[key];
                        if (child.type === 'StructDefinition' && child.name.startsWith('__state_def_')) {
                            addStateTx(knownStateTx, 'def', child.name.substring('__state_def_'.length));
                        } else if (child.type === 'FunctionDefinition' && child.name.startsWith('__state_hash_')) {
                            addStateTx(knownStateTx, 'hash', child.name.substring('__state_hash_'.length));
                        } else if (child.type === 'StructDefinition' && child.name.startsWith('__tx_arg_')) {
                            addStateTx(knownStateTx, 'arg', child.name.substring('__tx_arg_'.length));
                        } else if (child.type === 'FunctionDefinition' && child.name.startsWith('__tx_do_')) {
                            addStateTx(knownStateTx, 'do', child.name.substring('__tx_do_'.length));
                        }
                    }

                    for (const name in knownStateTx) {
                        if (!(knownStateTx[name]['def'] && knownStateTx[name]['hash'] && knownStateTx[name]['arg'] && knownStateTx[name]['do'])) {
                            throw new Error(`'def', 'hash', 'arg' and 'do' should be defined with ${name}.`)
                        } else {
                            console.log(`Find: ${name}.`)
                        }
                    }

                    // Add procedures to the code

                    for (const stateTxName in knownStateTx) {

                        function recursiveProceed(node, action) {
                            action(node);

                            for (const [key, value] of Object.entries(node)) {
                                if (underscore.isObject(value)) {
                                    recursiveProceed(value, action);
                                }
                            }
                        }

                        const removeNodeLocation = (node) => recursiveProceed(node, (node) => {
                            delete node.loc;
                            delete node.range;
                        });

                        const renameNode = (node, name) => recursiveProceed(node, (node) => {
                            for (const [key, value] of Object.entries(node)) {
                                if (templateNames.includes(value)) {
                                    node[key] = value.replace('NAME', name);
                                }
                            }
                        });

                        for (const [key, node] of Object.entries(templateAst)) {
                            const newNode = underscore.extend(node);
                            removeNodeLocation(newNode);
                            renameNode(newNode, stateTxName);
                            contract.subNodes.push(newNode);
                        }
                    }

                }

                return ast;
            },
            astFormat: 'solidity-ast',
            locStart: prettierPluginSolidity.parsers["solidity-parse"].locStart,
            locEnd: prettierPluginSolidity.parsers["solidity-parse"].locEnd,
        },
    },
    printers: prettierPluginSolidity.printers,
    options: prettierPluginSolidity.options,
    defaultOptions: prettierPluginSolidity.defaultOptions,
}
const options = {
    'plugins': ['prettier-plugin-solidity', myPlugin], 'parser': 'solidity-mod-parse',
};

const templateFilename = './template.sol';
const templateAstFilterPartial = {
    'StructDefinition': ['__state_comp_element_NAME',],
    'FunctionDefinition': ['__tx_online_NAME', '__tx_proof_NAME', '__tx_offline_NAME', '__tx_commit_NAME', '__tx_pending_len_NAME', '__tx_state_latest_NAME',],
};
const templateNames = ['__state_comp_element_NAME', '__tx_online_NAME', '__tx_proof_NAME', '__tx_offline_NAME', '__tx_commit_NAME', '__tx_pending_len_NAME', '__tx_state_latest_NAME', '__state_def_NAME', '__tx_arg_NAME', '__state_comp_dict_NAME', '__tx_do_NAME', '__state_hash_NAME',]
const templateAst = {};
data = fs.readFileSync(templateFilename, 'utf8');

const ast = prettierPluginSolidity.parsers["solidity-parse"].parse(data, prettierPluginSolidity.parsers, prettierPluginSolidity.defaultOptions);

for (const contractKey in ast.children) {
    const contract = ast.children[contractKey];
    if (contract.type !== "ContractDefinition" || contract.name !== '__Template') continue;

    for (const key in contract.subNodes) {
        const child = contract.subNodes[key];
        if (child.type in templateAstFilterPartial && templateAstFilterPartial[child.type].includes(child.name)) {
            templateAst[child.name] = child;
        } else if (child.type === 'StateVariableDeclaration' && child.variables[0].type === 'VariableDeclaration' && child.variables[0].name === '__state_comp_dict_NAME') {
            templateAst[child.variables[0].name] = child;
        }
    }
}

const inputFilename = process.argv[2];
const outputFilename = process.argv[3];

if (underscore.isEmpty(inputFilename) || underscore.isEmpty(outputFilename)) {
    console.error('Please specify the input and output file.')
    exit(1);
}

data = fs.readFileSync(inputFilename, 'utf8');

outputText = prettier.format(data, options);
fs.writeFileSync(outputFilename, outputText, 'utf8');

console.log(`Output file written to ${outputFilename}.`);

