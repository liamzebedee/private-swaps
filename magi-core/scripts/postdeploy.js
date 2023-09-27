module.exports = async function (niacin) {
    const {
        MockDAI,
        Tempest
    } = niacin.contracts

    if (MockDAI) {
        await niacin.initialize({
            contract: MockDAI,
            args: []
        })
    }

    await niacin.initialize({
        contract: Tempest,
        args: []
    })
}