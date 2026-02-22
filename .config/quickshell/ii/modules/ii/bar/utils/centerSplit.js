// utils/centerSplit.js
.pragma library

function split(model) {
    if (!model || model.length === undefined) {
        return { leftList: [], centerList: [], rightList: [] }
    }

    const idx = model.findIndex(item => item && item.centered === true)

    if (idx === -1) {
        return { leftList: [], centerList: model, rightList: [] }
    }

    return {
        leftList: model.slice(0, idx),
        centerList: [model[idx]],
        rightList: model.slice(idx + 1),
    }
}
